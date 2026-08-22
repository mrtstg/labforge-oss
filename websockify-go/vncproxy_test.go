package main

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"
	"time"
)

func TestLookupNodeRefreshesRejectedServiceToken(t *testing.T) {
	var authRequests atomic.Int32
	authServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		request := authRequests.Add(1)
		_ = json.NewEncoder(w).Encode(authGrantResponse{
			AccessToken: tokenForRequest(request),
			ExpiresIn:   300,
		})
	}))
	defer authServer.Close()

	var clusterRequests atomic.Int32
	clusterServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		clusterRequests.Add(1)
		if r.Method != http.MethodGet || r.URL.Path != "/api/cluster/vm/1001/node" {
			t.Errorf("unexpected cluster request: %s %s", r.Method, r.URL.Path)
		}
		switch r.Header.Get("Authorization") {
		case "Bearer token-1":
			w.WriteHeader(http.StatusUnauthorized)
		case "Bearer token-2":
			_ = json.NewEncoder(w).Encode("nested-pve-2")
		default:
			t.Errorf("unexpected authorization header: %q", r.Header.Get("Authorization"))
			w.WriteHeader(http.StatusForbidden)
		}
	}))
	defer clusterServer.Close()

	handler := &WebsocketVncProxyHandler{
		httpClient: &http.Client{Timeout: time.Second},
		conf: ProxyConfig{
			ClusterURL:    clusterServer.URL,
			ServiceTokens: newTestServiceTokenClient(authServer.URL),
		},
	}
	node, err := handler.lookupNode(context.Background(), 1001)
	if err != nil {
		t.Fatal(err)
	}
	if node != "nested-pve-2" {
		t.Fatalf("unexpected node: %q", node)
	}
	if authRequests.Load() != 2 || clusterRequests.Load() != 2 {
		t.Fatalf("unexpected request counts: auth=%d cluster=%d", authRequests.Load(), clusterRequests.Load())
	}
}

func TestLookupNodeRejectsInvalidNodeName(t *testing.T) {
	authServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_ = json.NewEncoder(w).Encode(authGrantResponse{AccessToken: "token", ExpiresIn: 300})
	}))
	defer authServer.Close()
	clusterServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_ = json.NewEncoder(w).Encode("../wrong-node")
	}))
	defer clusterServer.Close()

	handler := &WebsocketVncProxyHandler{
		httpClient: &http.Client{Timeout: time.Second},
		conf: ProxyConfig{
			ClusterURL:    clusterServer.URL,
			ServiceTokens: newTestServiceTokenClient(authServer.URL),
		},
	}
	if _, err := handler.lookupNode(context.Background(), 1001); err == nil {
		t.Fatal("expected invalid node name to fail")
	}
}

func TestUpstreamStatusMapsServiceFailures(t *testing.T) {
	if got := upstreamStatus(&serviceError{service: "cluster-manager", status: http.StatusNotFound}); got != http.StatusConflict {
		t.Fatalf("unexpected not-found mapping: %d", got)
	}
	if got := upstreamStatus(&serviceError{service: "auth-service", status: http.StatusNotFound}); got != http.StatusBadGateway {
		t.Fatalf("unexpected auth not-found mapping: %d", got)
	}
	if got := upstreamStatus(&serviceError{service: "auth-service", timeout: true}); got != http.StatusGatewayTimeout {
		t.Fatalf("unexpected timeout mapping: %d", got)
	}
	if got := upstreamStatus(errors.New("bad response")); got != http.StatusBadGateway {
		t.Fatalf("unexpected generic mapping: %d", got)
	}
}

func tokenForRequest(request int32) string {
	if request == 1 {
		return "token-1"
	}
	return "token-2"
}
