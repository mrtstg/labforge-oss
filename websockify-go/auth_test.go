package main

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

func TestServiceTokenClientIssuesAndCachesToken(t *testing.T) {
	var requests atomic.Int32
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requests.Add(1)
		if r.Method != http.MethodPost || r.URL.Path != "/api/auth" {
			t.Errorf("unexpected auth request: %s %s", r.Method, r.URL.Path)
		}
		if r.Header.Get("Content-Type") != "application/json" {
			t.Errorf("unexpected content type: %q", r.Header.Get("Content-Type"))
		}
		var request authGrantRequest
		if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
			t.Error(err)
		}
		if request.GrantType != "client_credentials" || request.ClientID != "websockify" || request.ClientSecret != "secret" {
			t.Errorf("unexpected grant request: %#v", request)
		}
		_ = json.NewEncoder(w).Encode(authGrantResponse{AccessToken: "service-token", ExpiresIn: 300})
	}))
	defer server.Close()

	client := newTestServiceTokenClient(server.URL)
	for range 2 {
		token, err := client.Token(context.Background())
		if err != nil {
			t.Fatal(err)
		}
		if token != "service-token" {
			t.Fatalf("unexpected token: %q", token)
		}
	}
	if got := requests.Load(); got != 1 {
		t.Fatalf("expected one auth request, got %d", got)
	}
}

func TestServiceTokenClientRefreshesBeforeExpiry(t *testing.T) {
	var requests atomic.Int32
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		request := requests.Add(1)
		_ = json.NewEncoder(w).Encode(authGrantResponse{AccessToken: "token-" + string(rune('0'+request)), ExpiresIn: 60})
	}))
	defer server.Close()

	client := newTestServiceTokenClient(server.URL)
	now := time.Unix(1_700_000_000, 0)
	client.now = func() time.Time { return now }
	first, err := client.Token(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	now = now.Add(31 * time.Second)
	second, err := client.Token(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if first != "token-1" || second != "token-2" || requests.Load() != 2 {
		t.Fatalf("unexpected refresh result: first=%q second=%q requests=%d", first, second, requests.Load())
	}
}

func TestServiceTokenClientSynchronizesConcurrentRefresh(t *testing.T) {
	var requests atomic.Int32
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		requests.Add(1)
		time.Sleep(10 * time.Millisecond)
		_ = json.NewEncoder(w).Encode(authGrantResponse{AccessToken: "shared-token", ExpiresIn: 300})
	}))
	defer server.Close()

	client := newTestServiceTokenClient(server.URL)
	const callers = 20
	var wait sync.WaitGroup
	wait.Add(callers)
	errorsFound := make(chan error, callers)
	for range callers {
		go func() {
			defer wait.Done()
			token, err := client.Token(context.Background())
			if err != nil {
				errorsFound <- err
				return
			}
			if token != "shared-token" {
				errorsFound <- &unexpectedTokenError{token: token}
			}
		}()
	}
	wait.Wait()
	close(errorsFound)
	for err := range errorsFound {
		t.Error(err)
	}
	if got := requests.Load(); got != 1 {
		t.Fatalf("expected one synchronized auth request, got %d", got)
	}
}

type unexpectedTokenError struct{ token string }

func (e *unexpectedTokenError) Error() string { return "unexpected token: " + e.token }

func TestServiceTokenClientRejectsInvalidResponse(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_, _ = w.Write([]byte(`{"access_token":"","expires_in":0}`))
	}))
	defer server.Close()

	if _, err := newTestServiceTokenClient(server.URL).Token(context.Background()); err == nil {
		t.Fatal("expected invalid auth response to fail")
	}
}

func newTestServiceTokenClient(url string) *ServiceTokenClient {
	return NewServiceTokenClient(AuthConfig{
		URL:          url,
		ClientID:     "websockify",
		ClientSecret: "secret",
		Timeout:      time.Second,
	})
}
