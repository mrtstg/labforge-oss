package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/xgfone/go-websocket"
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

func TestPipeRelaysBothDirectionsAndLargeProxmoxMessage(t *testing.T) {
	gatewaySource, browser := newWebsocketPair(t)
	gatewayTarget, proxmox := newWebsocketPair(t)
	gatewaySource.SetTimeout(time.Second).SetMaxMsgSize(defaultClientMaxMessageSize)
	gatewayTarget.SetTimeout(time.Second).SetMaxMsgSize(defaultProxmoxMaxMessageSize)

	p := newTestPeer(gatewaySource, gatewayTarget, ProxyConfig{
		ClientMaxMessageSize: defaultClientMaxMessageSize,
		Proxmox:              &ProxmoxClient{maxMessageSize: defaultProxmoxMaxMessageSize},
	})
	h := &WebsocketVncProxyHandler{conf: p.conf}
	go h.pipe(p, p.source, p.sendTargetMsg, "client", nil)
	go h.pipe(p, p.target, p.sendSourceMsg, "Proxmox", nil)

	clientPayload := []byte("client-to-Proxmox")
	wantClientPayload := string(clientPayload)
	if err := browser.SendBinaryMsg(clientPayload); err != nil {
		t.Fatal(err)
	}
	if got := receiveBinaryMessage(t, proxmox); string(got) != wantClientPayload {
		t.Fatalf("unexpected Proxmox payload: %q", got)
	}

	proxmoxPayload := make([]byte, 128<<10)
	for i := range proxmoxPayload {
		proxmoxPayload[i] = byte(i)
	}
	wantProxmoxPayload := string(proxmoxPayload)
	if err := proxmox.SendBinaryMsg(proxmoxPayload); err != nil {
		t.Fatal(err)
	}
	if got := receiveBinaryMessage(t, browser); string(got) != wantProxmoxPayload {
		t.Fatalf("large Proxmox payload was not relayed: got=%d want=%d", len(got), len(proxmoxPayload))
	}
	if p.clientToProxmoxBytes.Load() != uint64(len(clientPayload)) || p.proxmoxToClientBytes.Load() != uint64(len(proxmoxPayload)) {
		t.Fatalf("unexpected byte counters: client=%d Proxmox=%d", p.clientToProxmoxBytes.Load(), p.proxmoxToClientBytes.Load())
	}
	p.Close("gateway", nil)
}

func TestHeartbeatKeepsIdleConnectionsAliveWhenPeersPong(t *testing.T) {
	gatewaySource, browser := newWebsocketPair(t)
	gatewayTarget, proxmox := newWebsocketPair(t)
	for _, ws := range []*websocket.Websocket{gatewaySource, gatewayTarget, browser, proxmox} {
		ws.SetTimeout(100 * time.Millisecond)
	}
	p := newTestPeer(gatewaySource, gatewayTarget, ProxyConfig{HeartbeatInterval: 10 * time.Millisecond, Timeout: 100 * time.Millisecond})
	h := &WebsocketVncProxyHandler{conf: p.conf}
	initialClientPong := p.lastClientPong.Load()
	initialProxmoxPong := p.lastProxmoxPong.Load()
	p.source.SetPongHander(func(ws *websocket.Websocket, _ []byte) {
		p.lastClientPong.Store(time.Now().UnixNano())
		_ = ws.SetDeadlineByDuration(100 * time.Millisecond)
	})
	p.target.SetPongHander(func(ws *websocket.Websocket, _ []byte) {
		p.lastProxmoxPong.Store(time.Now().UnixNano())
		_ = ws.SetDeadlineByDuration(100 * time.Millisecond)
	})
	go consumeWebsocket(browser)
	go consumeWebsocket(proxmox)
	go consumeWebsocket(gatewaySource)
	go consumeWebsocket(gatewayTarget)
	go h.heartbeat(p)

	time.Sleep(50 * time.Millisecond)
	if atomic.LoadInt32(&p.closed) != 0 {
		t.Fatal("healthy idle connection was closed")
	}
	if p.lastClientPong.Load() <= initialClientPong || p.lastProxmoxPong.Load() <= initialProxmoxPong {
		t.Fatal("heartbeat pongs were not observed on both websocket legs")
	}
	p.Close("gateway", nil)
}

func TestHeartbeatClosesConnectionWhenProxmoxDoesNotPong(t *testing.T) {
	gatewaySource, browser := newWebsocketPair(t)
	gatewayTarget, _ := newWebsocketPair(t)
	for _, ws := range []*websocket.Websocket{gatewaySource, gatewayTarget, browser} {
		ws.SetTimeout(40 * time.Millisecond)
	}
	p := newTestPeer(gatewaySource, gatewayTarget, ProxyConfig{HeartbeatInterval: 10 * time.Millisecond, Timeout: 40 * time.Millisecond})
	h := &WebsocketVncProxyHandler{conf: p.conf}
	go consumeWebsocket(browser)
	go consumeWebsocket(gatewaySource)
	// The real Proxmox-to-client pipe is what observes the read deadline. Its
	// peer intentionally never reads the ping, so no pong is generated.
	go h.pipe(p, p.target, p.sendSourceMsg, "Proxmox", nil)
	go h.heartbeat(p)

	deadline := time.After(500 * time.Millisecond)
	for atomic.LoadInt32(&p.closed) == 0 {
		select {
		case <-deadline:
			t.Fatal("connection without a Proxmox pong was not closed")
		case <-time.After(5 * time.Millisecond):
		}
	}
}

func TestPipeLogsOversizedMessageWithoutPayload(t *testing.T) {
	gatewaySource, browser := newWebsocketPair(t)
	gatewayTarget, _ := newWebsocketPair(t)
	gatewaySource.SetTimeout(time.Second).SetMaxMsgSize(64)
	logResult := make(chan string, 1)
	conf := ProxyConfig{
		ClientMaxMessageSize: 64,
		ErrorLog: func(format string, args ...interface{}) {
			select {
			case logResult <- formatLog(format, args...):
			default:
			}
		},
	}
	p := newTestPeer(gatewaySource, gatewayTarget, conf)
	h := &WebsocketVncProxyHandler{conf: conf}
	go h.pipe(p, p.source, p.sendTargetMsg, "client", nil)

	payload := []byte("payload-that-must-never-appear-in-logs-" + strings.Repeat("x", 128))
	if err := browser.SendBinaryMsg(payload); err != nil {
		t.Fatal(err)
	}
	select {
	case logLine := <-logResult:
		if !strings.Contains(logLine, "event=vnc_oversized_message") || !strings.Contains(logLine, "limit=64") {
			t.Fatalf("unexpected oversized-message log: %s", logLine)
		}
		if strings.Contains(logLine, "payload-that-must-never-appear") {
			t.Fatalf("oversized-message log leaked payload: %s", logLine)
		}
	case <-time.After(time.Second):
		t.Fatal("oversized message was not logged")
	}
}

func TestCloseSummaryContainsDiagnosticsWithoutCredentials(t *testing.T) {
	gatewaySource, _ := newWebsocketPair(t)
	gatewayTarget, _ := newWebsocketPair(t)
	var logLine string
	p := newTestPeer(gatewaySource, gatewayTarget, ProxyConfig{
		InfoLog: func(format string, args ...interface{}) {
			logLine = formatLog(format, args...)
		},
	})
	p.header = "Bearer must-not-be-logged"
	p.clientToProxmoxBytes.Store(10)
	p.proxmoxToClientBytes.Store(20)
	p.Close("Proxmox", io.EOF)

	for _, expected := range []string{"event=vnc_closed", "connection_id=1", "reason=eof_or_reset", "client_to_proxmox_bytes=10", "proxmox_to_client_bytes=20"} {
		if !strings.Contains(logLine, expected) {
			t.Fatalf("close log is missing %q: %s", expected, logLine)
		}
	}
	if strings.Contains(logLine, "must-not-be-logged") {
		t.Fatalf("close log leaked authorization header: %s", logLine)
	}
}

func TestClassifyCloseReasonRecognizesFragmentedOversizedMessage(t *testing.T) {
	err := errors.New("[1009]The message is too big")
	if got := classifyCloseReason("Proxmox", err); got != "message_too_big" {
		t.Fatalf("unexpected close reason: %s", got)
	}
}

func newWebsocketPair(t *testing.T) (*websocket.Websocket, *websocket.Websocket) {
	t.Helper()
	serverSide := make(chan *websocket.Websocket, 1)
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ws, err := (websocket.Upgrader{Subprotocols: []string{"binary"}}).Upgrade(w, r, nil)
		if err != nil {
			return
		}
		serverSide <- ws
	}))
	t.Cleanup(server.Close)
	client, err := websocket.NewClientWebsocket("ws"+strings.TrimPrefix(server.URL, "http"), websocket.ClientOption{Protocol: []string{"binary"}})
	if err != nil {
		t.Fatal(err)
	}
	serverWS := <-serverSide
	t.Cleanup(func() {
		_ = client.SendClose(websocket.CloseNormalClosure, "test complete")
		_ = serverWS.SendClose(websocket.CloseNormalClosure, "test complete")
	})
	return serverWS, client
}

func newTestPeer(source, target *websocket.Websocket, conf ProxyConfig) *peer {
	now := time.Now()
	p := &peer{
		id: 1, source: source, target: target, vm: "1001", node: "node1", client: "test-client",
		start: now, conf: conf, done: make(chan struct{}),
	}
	for _, value := range []*atomic.Int64{&p.lastClientActivity, &p.lastProxmoxActivity, &p.lastClientPong, &p.lastProxmoxPong} {
		value.Store(now.UnixNano())
	}
	return p
}

func consumeWebsocket(ws *websocket.Websocket) {
	for {
		if _, err := ws.RecvMsg(); err != nil {
			return
		}
	}
}

func formatLog(format string, args ...interface{}) string {
	return fmt.Sprintf(format, args...)
}
