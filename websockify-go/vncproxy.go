// Copyright 2023 xgfone
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"reflect"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/xgfone/go-websocket"
)

type peer struct {
	id     uint64
	source *websocket.Websocket
	target *websocket.Websocket
	header string
	vm     string
	node   string
	client string
	start  time.Time
	closed int32
	conf   ProxyConfig
	done   chan struct{}

	sourceMu sync.Mutex // serializes writes to the browser websocket
	targetMu sync.Mutex // serializes writes to the Proxmox websocket

	clientToProxmoxBytes    atomic.Uint64
	clientToProxmoxMessages atomic.Uint64
	proxmoxToClientBytes    atomic.Uint64
	proxmoxToClientMessages atomic.Uint64
	lastClientActivity      atomic.Int64
	lastProxmoxActivity     atomic.Int64
	lastClientPing          atomic.Int64
	lastProxmoxPing         atomic.Int64
	lastClientPong          atomic.Int64
	lastProxmoxPong         atomic.Int64
	connections             func() int64
}

func (p *peer) Close(from string, err error) {
	if atomic.CompareAndSwapInt32(&p.closed, 0, 1) {
		close(p.done)
		p.targetMu.Lock()
		_ = p.target.SendClose(websocket.CloseNormalClosure, "close")
		p.targetMu.Unlock()
		p.sourceMu.Lock()
		_ = p.source.SendClose(websocket.CloseNormalClosure, "close")
		p.sourceMu.Unlock()
		now := time.Now()
		var connections int64
		if p.connections != nil {
			connections = p.connections()
		}
		p.conf.infof("event=vnc_closed connection_id=%d vm=%s node=%s client=%s duration=%s from=%s reason=%s err_type=%s err=%q client_to_proxmox_bytes=%d client_to_proxmox_messages=%d proxmox_to_client_bytes=%d proxmox_to_client_messages=%d client_idle=%s proxmox_idle=%s client_pong_age=%s proxmox_pong_age=%s connections=%d",
			p.id, p.vm, p.node, p.client, now.Sub(p.start), from, classifyCloseReason(from, err), errorType(err), errorText(err),
			p.clientToProxmoxBytes.Load(), p.clientToProxmoxMessages.Load(), p.proxmoxToClientBytes.Load(), p.proxmoxToClientMessages.Load(),
			ageSince(now, p.lastClientActivity.Load()), ageSince(now, p.lastProxmoxActivity.Load()), ageSince(now, p.lastClientPong.Load()), ageSince(now, p.lastProxmoxPong.Load()), connections)
	}
}

// sendTargetMsg is the single serialized write path to the Proxmox websocket.
// Relay data and keepalive frames share this lock so their ordering stays
// deterministic even when a socket write takes more than one system call.
func (p *peer) sendTargetMsg(data []byte) error {
	p.targetMu.Lock()
	defer p.targetMu.Unlock()
	if err := p.target.SendBinaryMsg(data); err != nil {
		return err
	}
	p.clientToProxmoxBytes.Add(uint64(len(data)))
	p.clientToProxmoxMessages.Add(1)
	p.lastClientActivity.Store(time.Now().UnixNano())
	return nil
}

// sendSourceMsg is the corresponding serialized path for framebuffer data
// travelling from Proxmox to the browser.
func (p *peer) sendSourceMsg(data []byte) error {
	p.sourceMu.Lock()
	defer p.sourceMu.Unlock()
	if err := p.source.SendBinaryMsg(data); err != nil {
		return err
	}
	p.proxmoxToClientBytes.Add(uint64(len(data)))
	p.proxmoxToClientMessages.Add(1)
	p.lastProxmoxActivity.Store(time.Now().UnixNano())
	return nil
}

// sendSourcePing serializes the keepalive ping to the browser websocket.
func (p *peer) sendSourcePing() error {
	p.sourceMu.Lock()
	defer p.sourceMu.Unlock()
	return p.source.SendPing(nil)
}

func (p *peer) sendTargetPing() error {
	p.targetMu.Lock()
	defer p.targetMu.Unlock()
	return p.target.SendPing(nil)
}

type ProxyConfig struct {
	ClusterURL           string
	ServiceTokens        *ServiceTokenClient
	TokenEndpoint        string
	Proxmox              *ProxmoxClient
	ErrorLog             func(format string, args ...interface{})
	InfoLog              func(format string, args ...interface{})
	ClientMaxMessageSize int
	Timeout              time.Duration
	HeartbeatInterval    time.Duration
	AccessCheckInterval  time.Duration
	UpgradeHeader        http.Header
	CheckOrigin          func(r *http.Request) bool
}

func (c ProxyConfig) errorf(format string, args ...interface{}) {
	if c.ErrorLog != nil {
		c.ErrorLog(format, args...)
	}
}

func (c ProxyConfig) infof(format string, args ...interface{}) {
	if c.InfoLog != nil {
		c.InfoLog(format, args...)
	}
}

type WebsocketVncProxyHandler struct {
	httpClient       *http.Client
	connection       int64
	nextConnectionID atomic.Uint64
	peers            map[*peer]struct{}
	exit             chan struct{}
	closeOnce        sync.Once
	lock             sync.RWMutex
	conf             ProxyConfig
	upgrader         websocket.Upgrader
}

func NewWebsocketVncProxyHandler(conf ProxyConfig) *WebsocketVncProxyHandler {
	if conf.Proxmox == nil {
		panic("Proxmox client is required")
	}
	if conf.ServiceTokens == nil {
		panic("service token client is required")
	}
	if conf.ClientMaxMessageSize <= 0 {
		conf.ClientMaxMessageSize = defaultClientMaxMessageSize
	}
	if conf.Timeout <= 0 {
		conf.Timeout = defaultTimeout
	}
	if conf.HeartbeatInterval <= 0 {
		conf.HeartbeatInterval = conf.Timeout * 8 / 10
	}
	if conf.AccessCheckInterval <= 0 {
		conf.AccessCheckInterval = conf.Timeout * 8 / 10
	}
	handler := &WebsocketVncProxyHandler{
		httpClient: &http.Client{Timeout: conf.Timeout},
		conf:       conf,
		exit:       make(chan struct{}),
		peers:      make(map[*peer]struct{}),
		upgrader: websocket.Upgrader{
			MaxMsgSize:   conf.ClientMaxMessageSize,
			Timeout:      conf.Timeout,
			Subprotocols: []string{"binary"},
			CheckOrigin:  conf.CheckOrigin,
		},
	}
	return handler
}

func (h *WebsocketVncProxyHandler) Connections() int64 {
	return atomic.LoadInt64(&h.connection)
}

func (h *WebsocketVncProxyHandler) addPeer(p *peer) {
	h.lock.Lock()
	h.peers[p] = struct{}{}
	h.lock.Unlock()
}

func (h *WebsocketVncProxyHandler) delPeer(p *peer) {
	h.lock.Lock()
	delete(h.peers, p)
	h.lock.Unlock()
}

func (h *WebsocketVncProxyHandler) peerSnapshot() []*peer {
	// Network access checks must not hold the peers lock; otherwise one slow
	// deployment-api response would block connection cleanup and registration.
	h.lock.RLock()
	peers := make([]*peer, 0, len(h.peers))
	for p := range h.peers {
		peers = append(peers, p)
	}
	h.lock.RUnlock()
	return peers
}

func (h *WebsocketVncProxyHandler) heartbeat(p *peer) {
	ticker := time.NewTicker(h.conf.HeartbeatInterval)
	defer ticker.Stop()
	for {
		select {
		case <-ticker.C:
			now := time.Now()
			if heartbeatExpired(now, p.lastClientPing.Load(), p.lastClientPong.Load(), h.conf.Timeout) {
				err := &heartbeatTimeoutError{leg: "client"}
				h.conf.errorf("event=vnc_heartbeat_error connection_id=%d vm=%s node=%s leg=client err_type=%s err=%q", p.id, p.vm, p.node, errorType(err), errorText(err))
				p.Close("client", err)
				return
			}
			if !heartbeatOutstanding(p.lastClientPing.Load(), p.lastClientPong.Load()) {
				p.lastClientPing.Store(now.UnixNano())
				if err := p.sendSourcePing(); err != nil {
					h.conf.errorf("event=vnc_heartbeat_error connection_id=%d vm=%s node=%s leg=client err_type=%s err=%q", p.id, p.vm, p.node, errorType(err), errorText(err))
					p.Close("client", err)
					return
				}
			}
			if heartbeatExpired(now, p.lastProxmoxPing.Load(), p.lastProxmoxPong.Load(), h.conf.Timeout) {
				err := &heartbeatTimeoutError{leg: "Proxmox"}
				h.conf.errorf("event=vnc_heartbeat_error connection_id=%d vm=%s node=%s leg=Proxmox err_type=%s err=%q", p.id, p.vm, p.node, errorType(err), errorText(err))
				p.Close("Proxmox", err)
				return
			}
			if !heartbeatOutstanding(p.lastProxmoxPing.Load(), p.lastProxmoxPong.Load()) {
				p.lastProxmoxPing.Store(now.UnixNano())
				if err := p.sendTargetPing(); err != nil {
					h.conf.errorf("event=vnc_heartbeat_error connection_id=%d vm=%s node=%s leg=Proxmox err_type=%s err=%q", p.id, p.vm, p.node, errorType(err), errorText(err))
					p.Close("Proxmox", err)
					return
				}
			}
		case <-p.done:
			return
		}
	}
}

func heartbeatOutstanding(lastPing, lastPong int64) bool {
	return lastPing != 0 && lastPing > lastPong
}

func heartbeatExpired(now time.Time, lastPing, lastPong int64, timeout time.Duration) bool {
	return heartbeatOutstanding(lastPing, lastPong) && now.Sub(time.Unix(0, lastPing)) >= timeout
}

type heartbeatTimeoutError struct{ leg string }

func (e *heartbeatTimeoutError) Error() string   { return e.leg + " heartbeat timed out" }
func (e *heartbeatTimeoutError) Timeout() bool   { return true }
func (e *heartbeatTimeoutError) Temporary() bool { return true }

func (h *WebsocketVncProxyHandler) revalidateAccess(p *peer) {
	ticker := time.NewTicker(h.conf.AccessCheckInterval)
	defer ticker.Stop()
	for {
		select {
		case <-ticker.C:
			h.validateAccess(p)
		case <-p.done:
			return
		}
	}
}

func (h *WebsocketVncProxyHandler) validateAccess(p *peer) {
	status, err := h.checkAccess(context.Background(), p.header, p.vm)
	if err != nil {
		h.conf.errorf("event=vnc_access_check_error connection_id=%d vm=%s node=%s err_type=%s err=%q", p.id, p.vm, p.node, errorType(err), errorText(err))
		return
	}
	if status >= 400 && status < 500 {
		h.conf.infof("event=vnc_access_revoked connection_id=%d vm=%s node=%s status=%d", p.id, p.vm, p.node, status)
		p.Close("authorization", nil)
	}
}

func (h *WebsocketVncProxyHandler) lookupNode(ctx context.Context, vmid int) (string, error) {
	const attempts = 3
	for attempt := 0; attempt < attempts; attempt++ {
		token, err := h.conf.ServiceTokens.Token(ctx)
		if err != nil {
			return "", err
		}
		node, status, err := h.lookupNodeWithToken(ctx, vmid, token)
		if status == http.StatusNotFound && attempt < attempts-1 {
			time.Sleep(time.Duration(attempt+1) * 200 * time.Millisecond)
			continue
		}
		if (status == http.StatusUnauthorized || status == http.StatusForbidden) && attempt == 0 {
			// The token may have been revoked or its service roles may have changed
			// before its advertised expiry. Refresh it and retry only once.
			h.conf.ServiceTokens.Invalidate(token)
			continue
		}
		return node, err
	}
	return "", errors.New("cluster-manager lookup failed")
}

func (h *WebsocketVncProxyHandler) lookupNodeWithToken(ctx context.Context, vmid int, token string) (string, int, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, fmt.Sprintf("%s/api/cluster/vm/%d/node", h.conf.ClusterURL, vmid), nil)
	if err != nil {
		return "", 0, err
	}
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := h.httpClient.Do(req)
	if err != nil {
		return "", 0, newServiceError("cluster-manager", 0, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		_, _ = io.Copy(io.Discard, io.LimitReader(resp.Body, maxServiceResponseSize))
		return "", resp.StatusCode, &serviceError{service: "cluster-manager", status: resp.StatusCode}
	}

	var node string
	if err := decodeServiceJSON(resp.Body, &node); err != nil {
		return "", resp.StatusCode, fmt.Errorf("invalid cluster-manager response: %w", err)
	}
	if !validNodeName(node) {
		return "", resp.StatusCode, errors.New("invalid cluster-manager node name")
	}
	return node, resp.StatusCode, nil
}

func (h *WebsocketVncProxyHandler) checkAccess(ctx context.Context, header, vm string) (int, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, h.conf.TokenEndpoint, nil)
	if err != nil {
		return 0, err
	}
	req.Header.Set("Authorization", header)
	req.Header.Set("X-VM-PORT", vm)
	resp, err := h.httpClient.Do(req)
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()
	_, _ = io.Copy(io.Discard, resp.Body)
	return resp.StatusCode, nil
}

func (h *WebsocketVncProxyHandler) Close() error {
	h.closeOnce.Do(func() {
		close(h.exit)
		for _, p := range h.peerSnapshot() {
			p.Close("gateway", nil)
		}
	})
	return nil
}

func (h *WebsocketVncProxyHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	start := time.Now()
	if !strings.EqualFold(r.Header.Get("Upgrade"), "websocket") {
		http.Error(w, "websocket upgrade required", http.StatusBadRequest)
		return
	}

	identifier := r.URL.Query().Get("token")
	target, err := ParseConsoleTarget(identifier)
	if err != nil {
		http.Error(w, "invalid console target", http.StatusBadRequest)
		return
	}
	tokenCookie, err := r.Cookie("token")
	if err != nil || tokenCookie.Value == "" {
		http.Error(w, "authentication required", http.StatusUnauthorized)
		return
	}
	authHeader := "Bearer " + tokenCookie.Value
	// nginx performs the same check on the public route, but repeating it here
	// keeps the gateway safe if it is accidentally reachable on its own port.
	accessStatus, err := h.checkAccess(r.Context(), authHeader, identifier)
	if err != nil {
		http.Error(w, http.StatusText(http.StatusBadGateway), http.StatusBadGateway)
		return
	}
	if accessStatus < 200 || accessStatus >= 300 {
		status := http.StatusBadGateway
		if accessStatus >= 400 && accessStatus < 500 {
			status = accessStatus
		}
		http.Error(w, http.StatusText(status), status)
		return
	}
	lookupCtx, lookupCancel := context.WithTimeout(r.Context(), h.conf.Timeout)
	node, err := h.lookupNode(lookupCtx, target.VMID)
	lookupCancel()
	if err != nil {
		status := upstreamStatus(err)
		h.conf.errorf("cannot resolve Proxmox node for VM %s: %v", identifier, err)
		http.Error(w, http.StatusText(status), status)
		return
	}
	target.Node = node

	ctx, cancel := context.WithTimeout(r.Context(), h.conf.Timeout)
	upstream, err := h.conf.Proxmox.OpenConsole(ctx, target)
	cancel()
	if err != nil {
		status := upstreamStatus(err)
		h.conf.errorf("cannot connect Proxmox console for %s: %v", identifier, err)
		http.Error(w, http.StatusText(status), status)
		return
	}

	source, err := h.upgrader.Upgrade(w, r, h.conf.UpgradeHeader)
	if err != nil {
		_ = upstream.SendClose(websocket.CloseNormalClosure, "client upgrade failed")
		return
	}
	// Proxmox has already accepted its private VNC password. Complete a separate
	// no-auth RFB negotiation with the authorized browser before relaying the
	// remainder of the byte stream in either direction.
	pending, err := negotiateBrowserRFB(source)
	if err != nil {
		_ = upstream.SendClose(websocket.CloseProtocolError, "browser RFB negotiation failed")
		_ = source.SendClose(websocket.CloseProtocolError, "RFB negotiation failed")
		h.conf.errorf("cannot negotiate browser RFB for %s: %v", identifier, err)
		return
	}

	p := &peer{
		id:          h.nextConnectionID.Add(1),
		source:      source,
		target:      upstream,
		header:      authHeader,
		vm:          identifier,
		node:        node,
		client:      r.RemoteAddr,
		start:       start,
		conf:        h.conf,
		done:        make(chan struct{}),
		connections: h.Connections,
	}
	nowUnix := time.Now().UnixNano()
	p.lastClientActivity.Store(nowUnix)
	p.lastProxmoxActivity.Store(nowUnix)
	p.lastClientPong.Store(nowUnix)
	p.lastProxmoxPong.Store(nowUnix)
	p.source.SetPongHander(func(ws *websocket.Websocket, _ []byte) {
		p.lastClientPong.Store(time.Now().UnixNano())
		_ = ws.SetDeadlineByDuration(h.conf.Timeout)
	})
	p.target.SetPongHander(func(ws *websocket.Websocket, _ []byte) {
		p.lastProxmoxPong.Store(time.Now().UnixNano())
		_ = ws.SetDeadlineByDuration(h.conf.Timeout)
	})
	atomic.AddInt64(&h.connection, 1)
	defer atomic.AddInt64(&h.connection, -1)
	h.addPeer(p)
	defer h.delPeer(p)
	h.conf.infof("event=vnc_connected connection_id=%d vm=%s node=%s client=%s cost=%s connections=%d", p.id, identifier, node, r.RemoteAddr, time.Since(start), h.Connections())
	go h.heartbeat(p)
	go h.revalidateAccess(p)

	go h.pipe(p, p.source, p.sendTargetMsg, "client", pending)
	h.pipe(p, p.target, p.sendSourceMsg, "Proxmox", nil)
}

func (h *WebsocketVncProxyHandler) pipe(p *peer, source *websocket.Websocket, send func([]byte) error, from string, initial []byte) {
	// Each write completes before the next read, providing backpressure without
	// buffering an unbounded amount of VNC traffic in the gateway. All target
	// writes use the direction-specific callback so they serialize with pings
	// and cannot accidentally be routed back to the websocket they came from.
	if len(initial) != 0 {
		if err := send(initial); err != nil {
			p.Close(from, err)
			return
		}
	}
	for {
		messages, err := source.RecvMsg()
		if err != nil {
			if isMessageTooBig(err) {
				limit := p.conf.ClientMaxMessageSize
				if from == "Proxmox" && p.conf.Proxmox != nil {
					limit = p.conf.Proxmox.maxMessageSize
				}
				h.conf.errorf("event=vnc_oversized_message connection_id=%d vm=%s node=%s from=%s limit=%d err=%q", p.id, p.vm, p.node, from, limit, err.Error())
			}
			p.Close(from, err)
			return
		}
		for _, message := range messages {
			if message.Type != websocket.MsgTypeBinary {
				p.Close(from, errors.New("non-binary websocket message"))
				return
			}
			if err := send(message.Data); err != nil {
				p.Close(from, err)
				return
			}
		}
	}
}

func classifyCloseReason(from string, err error) string {
	if err == nil {
		switch from {
		case "authorization":
			return "access_revoked"
		case "gateway":
			return "gateway_shutdown"
		default:
			return "clean_close"
		}
	}
	var netErr net.Error
	if errors.As(err, &netErr) && netErr.Timeout() {
		return "timeout"
	}
	if errors.Is(err, io.EOF) || strings.Contains(strings.ToLower(err.Error()), "connection reset") {
		return "eof_or_reset"
	}
	if isMessageTooBig(err) {
		return "message_too_big"
	}
	if strings.HasPrefix(err.Error(), "[") {
		return "websocket_close"
	}
	if strings.Contains(strings.ToLower(err.Error()), "protocol") || strings.Contains(strings.ToLower(err.Error()), "non-binary") {
		return "protocol_error"
	}
	return "io_error"
}

func isMessageTooBig(err error) bool {
	return err != nil && strings.Contains(strings.ToLower(err.Error()), "message is too big")
}

func errorType(err error) string {
	if err == nil {
		return "none"
	}
	return reflect.TypeOf(err).String()
}

func errorText(err error) string {
	if err == nil {
		return ""
	}
	return err.Error()
}

func ageSince(now time.Time, unixNano int64) time.Duration {
	if unixNano == 0 {
		return 0
	}
	return now.Sub(time.Unix(0, unixNano))
}

func upstreamStatus(err error) int {
	var serviceErr *serviceError
	if errors.As(err, &serviceErr) {
		if serviceErr.timeout {
			return http.StatusGatewayTimeout
		}
		if serviceErr.service == "cluster-manager" && serviceErr.status == http.StatusNotFound {
			return http.StatusConflict
		}
		return http.StatusBadGateway
	}
	var pveErr *upstreamError
	if errors.As(err, &pveErr) {
		if pveErr.timeout {
			return http.StatusGatewayTimeout
		}
		if pveErr.status == http.StatusBadRequest || pveErr.status == http.StatusNotFound {
			return http.StatusConflict
		}
	}
	return http.StatusBadGateway
}
