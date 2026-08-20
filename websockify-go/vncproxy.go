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
	"io"
	"net/http"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/xgfone/go-websocket"
)

type peer struct {
	source *websocket.Websocket
	target *websocket.Websocket
	header string
	vm     string
	start  time.Time
	closed int32
	conf   ProxyConfig
}

func (p *peer) Close(from string, err error) {
	if atomic.CompareAndSwapInt32(&p.closed, 0, 1) {
		_ = p.target.SendClose(websocket.CloseNormalClosure, "close")
		_ = p.source.SendClose(websocket.CloseNormalClosure, "close")
		p.conf.infof("close VNC: vm=%s, duration=%s, from=%s, err=%v", p.vm, time.Since(p.start), from, err)
	}
}

type ProxyConfig struct {
	TokenEndpoint string
	Proxmox       *ProxmoxClient
	ErrorLog      func(format string, args ...interface{})
	InfoLog       func(format string, args ...interface{})
	MaxMsgSize    int
	Timeout       time.Duration
	UpgradeHeader http.Header
	CheckOrigin   func(r *http.Request) bool
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
	httpClient *http.Client
	connection int64
	peers      map[*peer]struct{}
	exit       chan struct{}
	closeOnce  sync.Once
	lock       sync.RWMutex
	conf       ProxyConfig
	upgrader   websocket.Upgrader
}

func NewWebsocketVncProxyHandler(conf ProxyConfig) *WebsocketVncProxyHandler {
	if conf.Proxmox == nil {
		panic("Proxmox client is required")
	}
	if conf.MaxMsgSize <= 0 {
		conf.MaxMsgSize = 65535
	}
	if conf.Timeout <= 0 {
		conf.Timeout = defaultTimeout
	}
	handler := &WebsocketVncProxyHandler{
		httpClient: &http.Client{Timeout: conf.Timeout},
		conf:       conf,
		exit:       make(chan struct{}),
		peers:      make(map[*peer]struct{}),
		upgrader: websocket.Upgrader{
			MaxMsgSize:   conf.MaxMsgSize,
			Timeout:      conf.Timeout,
			Subprotocols: []string{"binary"},
			CheckOrigin:  conf.CheckOrigin,
		},
	}
	go handler.tick()
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

func (h *WebsocketVncProxyHandler) tick() {
	ticker := time.NewTicker(h.conf.Timeout * 8 / 10)
	defer ticker.Stop()
	for {
		select {
		case <-ticker.C:
			for _, p := range h.peerSnapshot() {
				if err := p.source.SendPing(nil); err != nil {
					p.Close("client", err)
					continue
				}
				if err := p.target.SendPing(nil); err != nil {
					p.Close("Proxmox", err)
					continue
				}
				h.validateAccess(p)
			}
		case <-h.exit:
			for _, p := range h.peerSnapshot() {
				p.Close("gateway", nil)
			}
			return
		}
	}
}

func (h *WebsocketVncProxyHandler) validateAccess(p *peer) {
	status, err := h.checkAccess(context.Background(), p.header, p.vm)
	if err != nil {
		h.conf.errorf("failed to validate access for %s: %v", p.vm, err)
		return
	}
	if status >= 400 && status < 500 {
		h.conf.infof("access revoked for %s", p.vm)
		p.Close("authorization", nil)
	}
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
	h.closeOnce.Do(func() { close(h.exit) })
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
		source: source,
		target: upstream,
		header: authHeader,
		vm:     identifier,
		start:  start,
		conf:   h.conf,
	}
	atomic.AddInt64(&h.connection, 1)
	defer atomic.AddInt64(&h.connection, -1)
	h.addPeer(p)
	defer h.delPeer(p)
	h.conf.infof("connected Proxmox console for %s, client=%s, cost=%s", identifier, r.RemoteAddr, time.Since(start))

	go h.pipe(p, p.source, p.target, "client", pending)
	h.pipe(p, p.target, p.source, "Proxmox", nil)
}

func (h *WebsocketVncProxyHandler) pipe(p *peer, source, target *websocket.Websocket, from string, initial []byte) {
	// Each write completes before the next read, providing backpressure without
	// buffering an unbounded amount of VNC traffic in the gateway.
	if len(initial) != 0 {
		if err := target.SendBinaryMsg(initial); err != nil {
			p.Close(from, err)
			return
		}
	}
	for {
		messages, err := source.RecvMsg()
		if err != nil {
			p.Close(from, err)
			return
		}
		for _, message := range messages {
			if message.Type != websocket.MsgTypeBinary {
				p.Close(from, errors.New("non-binary websocket message"))
				return
			}
			if err := target.SendBinaryMsg(message.Data); err != nil {
				p.Close(from, err)
				return
			}
		}
	}
}

func upstreamStatus(err error) int {
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
