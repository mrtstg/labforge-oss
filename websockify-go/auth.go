package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"sync"
	"time"
)

const (
	serviceTokenRefreshSkew = 30 * time.Second
	maxServiceResponseSize  = 1 << 20
)

type authGrantRequest struct {
	GrantType    string `json:"grant_type"`
	ClientID     string `json:"client_id"`
	ClientSecret string `json:"client_secret"`
}

type authGrantResponse struct {
	AccessToken string `json:"access_token"`
	ExpiresIn   int64  `json:"expires_in"`
}

// ServiceTokenClient owns the websockify client-credentials token. The two
// locks let readers use a valid cached token concurrently while ensuring only
// one caller contacts auth-service when a refresh is required.
type ServiceTokenClient struct {
	url          string
	clientID     string
	clientSecret string
	http         *http.Client
	now          func() time.Time

	stateMu   sync.RWMutex
	refreshMu sync.Mutex
	token     string
	expiresAt time.Time
}

func NewServiceTokenClient(config AuthConfig) *ServiceTokenClient {
	timeout := config.Timeout
	if timeout <= 0 {
		timeout = defaultTimeout
	}
	return &ServiceTokenClient{
		url:          config.URL + "/api/auth",
		clientID:     config.ClientID,
		clientSecret: config.ClientSecret,
		http:         &http.Client{Timeout: timeout},
		now:          time.Now,
	}
}

func (c *ServiceTokenClient) Token(ctx context.Context) (string, error) {
	if token, ok := c.cachedToken(); ok {
		return token, nil
	}

	// Recheck after taking the refresh lock because another caller may have
	// refreshed while this caller was waiting.
	c.refreshMu.Lock()
	defer c.refreshMu.Unlock()
	if token, ok := c.cachedToken(); ok {
		return token, nil
	}
	return c.issue(ctx)
}

func (c *ServiceTokenClient) cachedToken() (string, bool) {
	c.stateMu.RLock()
	defer c.stateMu.RUnlock()
	return c.token, c.token != "" && c.now().Add(serviceTokenRefreshSkew).Before(c.expiresAt)
}

// Invalidate removes only the token rejected by a downstream service. If a
// concurrent request has already refreshed it, that newer token is preserved.
func (c *ServiceTokenClient) Invalidate(rejectedToken string) {
	c.stateMu.Lock()
	if c.token == rejectedToken {
		c.token = ""
		c.expiresAt = time.Time{}
	}
	c.stateMu.Unlock()
}

func (c *ServiceTokenClient) issue(ctx context.Context) (string, error) {
	payload, err := json.Marshal(authGrantRequest{
		GrantType:    "client_credentials",
		ClientID:     c.clientID,
		ClientSecret: c.clientSecret,
	})
	if err != nil {
		return "", err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.url, bytes.NewReader(payload))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.http.Do(req)
	if err != nil {
		return "", newServiceError("auth-service", 0, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		_, _ = io.Copy(io.Discard, io.LimitReader(resp.Body, maxServiceResponseSize))
		return "", &serviceError{service: "auth-service", status: resp.StatusCode}
	}

	var grant authGrantResponse
	if err := decodeServiceJSON(resp.Body, &grant); err != nil {
		return "", fmt.Errorf("invalid auth-service response: %w", err)
	}
	if grant.AccessToken == "" || grant.ExpiresIn <= 0 {
		return "", errors.New("invalid auth-service response")
	}

	now := c.now()
	c.stateMu.Lock()
	c.token = grant.AccessToken
	c.expiresAt = now.Add(time.Duration(grant.ExpiresIn) * time.Second)
	c.stateMu.Unlock()
	return grant.AccessToken, nil
}

type serviceError struct {
	service string
	status  int
	timeout bool
}

func (e *serviceError) Error() string {
	if e.timeout {
		return e.service + " request timed out"
	}
	if e.status != 0 {
		return fmt.Sprintf("%s request failed with status %d", e.service, e.status)
	}
	return e.service + " request failed"
}

func newServiceError(service string, status int, err error) *serviceError {
	var netErr net.Error
	return &serviceError{
		service: service,
		status:  status,
		timeout: errors.Is(err, context.DeadlineExceeded) || (errors.As(err, &netErr) && netErr.Timeout()),
	}
}

func decodeServiceJSON(body io.Reader, target any) error {
	limited, err := io.ReadAll(io.LimitReader(body, maxServiceResponseSize+1))
	if err != nil {
		return err
	}
	if len(limited) > maxServiceResponseSize {
		return errors.New("response is too large")
	}
	if err := json.Unmarshal(limited, target); err != nil {
		return err
	}
	return nil
}
