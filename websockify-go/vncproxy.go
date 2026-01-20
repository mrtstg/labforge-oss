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

// Package vncproxy provides a HTTP handler about VNC Proxy on Websocket.
package main

import (
	"crypto/tls"
	"fmt"
	"io"
	"net"
	"net/http"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/xgfone/go-websocket"
)

type peer struct {
	ProxyConfig

	source *websocket.Websocket
	target *net.TCPConn
	closed int32
	start  time.Time
}

func (p *peer) Close(addr string, err error) {
	if atomic.CompareAndSwapInt32(&p.closed, 0, 1) {
		p.target.Close()
		p.source.SendClose(websocket.CloseNormalClosure, "close")
		p.infof("close VNC: source=%s, target=%s, duration=%s, from=%s, err=%v",
			p.source.RemoteAddr().String(), p.target.RemoteAddr().String(),
			time.Since(p.start).String(), addr, err)
	}
}

func newPeer(source *websocket.Websocket, target *net.TCPConn, now time.Time, c ProxyConfig) *peer {
	return &peer{source: source, target: target, start: now, ProxyConfig: c}
}

// ProxyConfig is used to configure WsVncProxyHandler.
type ProxyConfig struct {
	TokenEndpoint string
	ErrorLog func(format string, args ...interface{})
	InfoLog  func(format string, args ...interface{})

	// MaxMsgSize is used to control the size of the websocket message.
	// The default is 64KB.
	MaxMsgSize int

	// The timeout is used to dial and the interval time of Ping-Pong.
	// The default is 10s.
	Timeout time.Duration

	// UpgradeHeader is the additional headers to upgrade the websocket.
	UpgradeHeader http.Header

	// Check whether the origin is allowed.
	//
	// The default is that the origin is allowed only when the header Origin
	// does not exist, or exists and is equal to the requesting host.
	CheckOrigin func(r *http.Request) bool

	// Return a backend address to connect to by the request.
	//
	// It's required.
	GetBackend func(r *http.Request) (addr string, err error)
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

type ConnectionDetails struct {
	header string
	vm string
}

// WebsocketVncProxyHandler is a VNC proxy handler based on websocket.
type WebsocketVncProxyHandler struct {
	httpClient *http.Client
	connection int64
	peers      map[*peer]ConnectionDetails
	exit       chan struct{}
	lock       sync.Mutex

	conf     ProxyConfig
	upgrader websocket.Upgrader
}

// NewWebsocketVncProxyHandler returns a new WebsocketVncProxyHandler.
//
// Notice: it only supports the binary protocol.
func NewWebsocketVncProxyHandler(conf ProxyConfig) *WebsocketVncProxyHandler {
	if conf.GetBackend == nil {
		panic(fmt.Errorf("GetBackend is required"))
	}
	if conf.MaxMsgSize <= 0 {
		conf.MaxMsgSize = 65535
	}
	if conf.Timeout <= 0 {
		conf.Timeout = time.Second * 10
	}

	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
		IdleConnTimeout: 5 * time.Second,
	}
	client := &http.Client{Transport: tr}
	handler := &WebsocketVncProxyHandler{
		httpClient: client,
		conf:  conf,
		exit:  make(chan struct{}),
		peers: make(map[*peer]ConnectionDetails, 1024),
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

// Connections returns the number of the current websockets.
func (h *WebsocketVncProxyHandler) Connections() int64 {
	return atomic.LoadInt64(&h.connection)
}

func (h *WebsocketVncProxyHandler) incConnection() {
	atomic.AddInt64(&h.connection, 1)
}

func (h *WebsocketVncProxyHandler) decConnection() {
	atomic.AddInt64(&h.connection, -1)
}

func (h *WebsocketVncProxyHandler) addPeer(p *peer, header string, vm string) {
	h.lock.Lock()
	h.peers[p] = ConnectionDetails { vm: vm, header: header }
	h.lock.Unlock()
}

func (h *WebsocketVncProxyHandler) delPeer(p *peer) {
	h.lock.Lock()
	delete(h.peers, p)
	h.lock.Unlock()
}

func (h *WebsocketVncProxyHandler) tick() {
	ticker := time.NewTicker(h.conf.Timeout * 8 / 10)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			isLocked := h.lock.TryLock()
			if isLocked {
				for peer, peerData := range h.peers {
					if err := peer.source.SendPing(nil); err != nil {
           		peer.Close(peer.source.RemoteAddr().String(), err)
          	  continue
        	}

					req, err := http.NewRequest("GET", h.conf.TokenEndpoint, nil)
					if err != nil {
						h.conf.errorf("Failed to create request for validating token")
						continue
					}
					req.Header.Set("Authorization", peerData.header)
					req.Header.Set("X-VM-PORT", peerData.vm)
					resp, err := h.httpClient.Do(req)
					if err != nil {
						h.conf.errorf("Failed to make check request: %s", err.Error())
						continue
					}
					io.Copy(io.Discard, resp.Body)
					resp.Body.Close()
					if resp.StatusCode >= 400 && resp.StatusCode <= 500 {
						h.conf.infof("Bad access check on %s\n", peerData.vm)
						delete(h.peers, peer)
						peer.Close("", nil)
					}
				}
				h.lock.Unlock()
			}
		case <-h.exit:
			ticker.Stop()
			h.lock.Lock()
			for peer := range h.peers {
				peer.Close("", nil)
				delete(h.peers, peer)
			}
			h.lock.Unlock()
			return
		}
	}
}

// Close implements the interface io.Closer.
func (h *WebsocketVncProxyHandler) Close() error { close(h.exit); return nil }

// ServeHTTP implements http.Handler, but it won't return until the connection
// has closed.
//
// Notice: for each connection, it will open other two goroutine,
// except itself goroutine, for reading from websocket and the backend VNC.
func (h *WebsocketVncProxyHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	starttime := time.Now()

	if strings.ToLower(r.Header.Get("Upgrade")) != "websocket" {
		w.Header().Set("Connection", "close")
		h.conf.errorf("not websocket: client=%s, upgrade=%s", r.RemoteAddr, r.Header.Get("Upgrade"))
		return
	}

	backend, err := h.conf.GetBackend(r)
	if err != nil {
		w.Header().Set("Connection", "close")
		h.conf.errorf("cannot get backend: client=%s, url=%s, err=%s", r.RemoteAddr, r.RequestURI, err)
		return
	} else if backend == "" {
		w.Header().Set("Connection", "close")
		h.conf.errorf("no backend: client=%s, url=%s", r.RemoteAddr, r.RequestURI)
		return
	}

	ws, err := h.upgrader.Upgrade(w, r, h.conf.UpgradeHeader)
	if err != nil {
		w.Header().Set("Connection", "close")
		h.conf.errorf("cannot upgrade to websocket: client=%s, err=%s", r.RemoteAddr, err)
		return
	}

	h.conf.infof("connecting to the VNC backend '%s' for '%s', url=%s", backend, r.RemoteAddr, r.RequestURI)

	c, err := net.DialTimeout("tcp", backend, h.conf.Timeout)
	if err != nil {
		h.conf.errorf("cannot connect to the VNC backend '%s': %s", backend, err)
		ws.SendClose(websocket.CloseAbnormalClosure, "cannot connect to the backend")
		return
	}
	h.conf.infof("connected to the VNC backend '%s' for '%s', cost=%s",
		backend, r.RemoteAddr, time.Since(starttime).String())

	// getting data for access check
	queryParams := r.URL.Query()
	vmToken := queryParams.Get("token")
	if vmToken == "" {
		h.conf.errorf("invalid vm token value")
		ws.SendClose(websocket.CloseAbnormalClosure, "cannot connect to the backend")
		return
	}
	tokenCookie, err := r.Cookie("token")
	if err != nil {
		h.conf.errorf("no token cookie provided")
		ws.SendClose(websocket.CloseAbnormalClosure, "cannot connect to the backend")
		return
	}
	cookieHeader := fmt.Sprintf("Bearer %s", tokenCookie.Value)

	h.incConnection()
	defer h.decConnection()
	peer := newPeer(ws, c.(*net.TCPConn), starttime, h.conf)
	h.addPeer(peer, cookieHeader, vmToken)
	defer h.delPeer(peer)

	go h.readSource(peer)
	h.readTarget(peer)
}

func (h *WebsocketVncProxyHandler) readSource(p *peer) {
	for {
		msgs, err := p.source.RecvMsg()
		if err != nil {
			p.Close(p.source.RemoteAddr().String(), err)
			return
		}

		for _, msg := range msgs {
			//if msg.Type == websocket.MsgTypeBinary {
			//	bytesAmount := len(msg.Data)
			//	if bytesAmount >= 2 {
			//		messageType, submessageType := int(msg.Data[0]), int(msg.Data[1])
			//		if messageType == 255 && submessageType == 0 && bytesAmount >= 12 {
			//			downFlag := uint16(msg.Data[2])<<8 | uint16(msg.Data[3])
			//			keyCode := binary.BigEndian.Uint32(msg.Data[4:8])
			//			if keyCode == 0xff0d && downFlag == 1 {
			//				fmt.Println("Pressed down enter!")
			//			} else {
			//				fmt.Printf("Pressed key %d %x\n", downFlag, keyCode)
			//			}
			//		}
			//	}
			//}
			if _, err = p.target.Write(msg.Data); err != nil {
				p.Close(p.target.RemoteAddr().String(), err)
			}
		}
	}
}

func (h *WebsocketVncProxyHandler) readTarget(p *peer) {
	for {
		buf := make([]byte, 2048)
		n, err := p.target.Read(buf)
		if err != nil {
			p.Close(p.target.RemoteAddr().String(), err)
			return
		}

		if err = p.source.SendBinaryMsg(buf[:n]); err != nil {
			p.Close(p.source.RemoteAddr().String(), err)
			return
		}
	}
}
