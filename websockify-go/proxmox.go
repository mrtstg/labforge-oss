package main

import (
	"context"
	"crypto/tls"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/xgfone/go-websocket"
)

type ConsoleTarget struct {
	Node string
	VMID int
}

type ProxmoxClient struct {
	baseURL        *url.URL
	apiToken       string
	tlsConfig      *tls.Config
	timeout        time.Duration
	maxMessageSize int
	http           *http.Client
}

type proxmoxProxyResponse struct {
	Data struct {
		Port     json.RawMessage `json:"port"`
		Ticket   string          `json:"ticket"`
		Password string          `json:"password"`
	} `json:"data"`
}

type consoleProxy struct {
	Port     string
	Ticket   string
	Password string
}

type upstreamError struct {
	status  int
	timeout bool
}

func (e *upstreamError) Error() string {
	if e.timeout {
		return "Proxmox request timed out"
	}
	return fmt.Sprintf("Proxmox request failed with status %d", e.status)
}

func NewProxmoxClient(config ProxmoxConfig) (*ProxmoxClient, error) {
	tlsConfig, err := buildTLSConfig(config)
	if err != nil {
		return nil, err
	}
	timeout := config.Timeout
	if timeout <= 0 {
		timeout = defaultTimeout
	}
	maxMessageSize := config.MaxMessageSize
	if maxMessageSize <= 0 {
		maxMessageSize = defaultProxmoxMaxMessageSize
	}
	transport := &http.Transport{
		TLSClientConfig: tlsConfig,
		IdleConnTimeout: 30 * time.Second,
	}
	return &ProxmoxClient{
		baseURL:        config.APIURL,
		apiToken:       config.APIToken,
		tlsConfig:      tlsConfig,
		timeout:        timeout,
		maxMessageSize: maxMessageSize,
		http:           &http.Client{Transport: transport, Timeout: timeout},
	}, nil
}

func ParseConsoleTarget(value string) (ConsoleTarget, error) {
	vmid, err := strconv.Atoi(value)
	if err != nil || vmid <= 0 {
		return ConsoleTarget{}, fmt.Errorf("invalid console target")
	}
	// get filled later in vncproxy module
	return ConsoleTarget{Node: "", VMID: vmid}, nil
}

func validNodeName(node string) bool {
	if node == "" {
		return false
	}
	for i, r := range node {
		if (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') || (r >= '0' && r <= '9') || (i > 0 && (r == '-' || r == '_' || r == '.')) {
			continue
		}
		return false
	}
	return true
}

func (c *ProxmoxClient) OpenConsole(ctx context.Context, target ConsoleTarget) (*websocket.Websocket, error) {
	// Proxmox vncproxy listeners and tickets are short-lived and must be created
	// afresh immediately before each vncwebsocket connection.
	proxy, err := c.createProxy(ctx, target)
	if err != nil {
		return nil, err
	}

	u := *c.baseURL
	u.Scheme = "wss"
	u.Path = fmt.Sprintf("/api2/json/nodes/%s/qemu/%d/vncwebsocket", url.PathEscape(target.Node), target.VMID)
	query := u.Query()
	query.Set("port", proxy.Port)
	query.Set("vncticket", proxy.Ticket)
	u.RawQuery = query.Encode()

	dialer := &net.Dialer{Timeout: c.timeout}
	ws, err := websocket.NewClientWebsocket(u.String(), websocket.ClientOption{
		Protocol: []string{"binary"},
		Header:   http.Header{"Authorization": []string{c.apiToken}},
		DialTLS: func(addr string) (net.Conn, error) {
			tcpConn, err := dialer.DialContext(ctx, "tcp", ensurePort(addr, "443"))
			if err != nil {
				return nil, err
			}
			tlsConfig := c.tlsConfig.Clone()
			tlsConfig.ServerName = c.baseURL.Hostname()
			tlsConn := tls.Client(tcpConn, tlsConfig)
			if err := tlsConn.HandshakeContext(ctx); err != nil {
				tcpConn.Close()
				return nil, err
			}
			return tlsConn, nil
		},
	})
	if err != nil {
		var netErr net.Error
		return nil, &upstreamError{timeout: errors.As(err, &netErr) && netErr.Timeout()}
	}
	ws.SetTimeout(c.timeout).SetMaxMsgSize(c.maxMessageSize)
	// The websocket upgrade only authenticates access to the short-lived VNC
	// listener. Complete the separate RFB password exchange here so neither the
	// ticket nor the generated console password ever has to reach the browser.
	if err := authenticateVNC(ws, proxy.Password); err != nil {
		_ = ws.SendClose(websocket.CloseProtocolError, "VNC authentication failed")
		return nil, fmt.Errorf("Proxmox VNC authentication failed: %w", err)
	}
	return ws, nil
}

func (c *ProxmoxClient) createProxy(ctx context.Context, target ConsoleTarget) (consoleProxy, error) {
	u := *c.baseURL
	u.Path = fmt.Sprintf("/api2/json/nodes/%s/qemu/%d/vncproxy", url.PathEscape(target.Node), target.VMID)
	// A generated password is preferable to using the ticket as the legacy VNC
	// DES key. It is single-use, returned only to this gateway, and never exposed
	// on the downstream websocket.
	form := url.Values{"websocket": {"1"}, "generate-password": {"1"}}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, u.String(), strings.NewReader(form.Encode()))
	if err != nil {
		return consoleProxy{}, err
	}
	req.Header.Set("Authorization", c.apiToken)
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := c.http.Do(req)
	if err != nil {
		return consoleProxy{}, &upstreamError{timeout: errors.Is(err, context.DeadlineExceeded)}
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return consoleProxy{}, &upstreamError{status: resp.StatusCode}
	}

	var payload proxmoxProxyResponse
	decoder := json.NewDecoder(io.LimitReader(resp.Body, 1<<20))
	if err := decoder.Decode(&payload); err != nil {
		return consoleProxy{}, fmt.Errorf("invalid Proxmox vncproxy response")
	}
	port, err := parsePort(payload.Data.Port)
	if err != nil || payload.Data.Ticket == "" || payload.Data.Password == "" {
		return consoleProxy{}, fmt.Errorf("invalid Proxmox vncproxy response")
	}
	return consoleProxy{Port: port, Ticket: payload.Data.Ticket, Password: payload.Data.Password}, nil
}

func parsePort(raw json.RawMessage) (string, error) {
	var value string
	if err := json.Unmarshal(raw, &value); err != nil {
		var number int
		if err := json.Unmarshal(raw, &number); err != nil {
			return "", err
		}
		value = strconv.Itoa(number)
	}
	port, err := strconv.Atoi(value)
	if err != nil || port < 1 || port > 65535 {
		return "", fmt.Errorf("invalid port")
	}
	return value, nil
}

func ensurePort(hostport, defaultPort string) string {
	if _, _, err := net.SplitHostPort(hostport); err == nil {
		return hostport
	}
	return net.JoinHostPort(hostport, defaultPort)
}
