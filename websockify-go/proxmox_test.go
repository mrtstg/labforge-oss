package main

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	"github.com/xgfone/go-websocket"
)

func TestParseConsoleTarget(t *testing.T) {
	tests := []struct {
		value string
		node  string
		vmid  int
		valid bool
	}{
		{value: "node1-101", node: "node1", vmid: 101, valid: true},
		{value: "nested-pve-1-101", node: "nested-pve-1", vmid: 101, valid: true},
		{value: "pve.example_1-999", node: "pve.example_1", vmid: 999, valid: true},
		{value: "node1", valid: false},
		{value: "-101", valid: false},
		{value: "node1-0", valid: false},
		{value: "node1-nope", valid: false},
		{value: "node/one-101", valid: false},
	}
	for _, test := range tests {
		t.Run(test.value, func(t *testing.T) {
			target, err := ParseConsoleTarget(test.value)
			if test.valid && err != nil {
				t.Fatal(err)
			}
			if !test.valid && err == nil {
				t.Fatalf("expected %q to be rejected", test.value)
			}
			if test.valid && (target.Node != test.node || target.VMID != test.vmid) {
				t.Fatalf("unexpected target: %#v", target)
			}
		})
	}
}

func TestCreateProxyRequest(t *testing.T) {
	var gotForm url.Values
	server := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api2/json/nodes/nested-pve-1/qemu/101/vncproxy" {
			t.Errorf("unexpected path: %s", r.URL.Path)
		}
		if got := r.Header.Get("Authorization"); got != "PVEAPIToken=gateway@pve!console=secret" {
			t.Errorf("unexpected Authorization header: %q", got)
		}
		if err := r.ParseForm(); err != nil {
			t.Error(err)
		}
		gotForm = r.Form
		_ = json.NewEncoder(w).Encode(map[string]any{
			"data": map[string]any{
				"port": "5901", "ticket": "PVEVNC:ticket/value+encoded", "password": "one-time-password",
			},
		})
	}))
	defer server.Close()

	baseURL, err := url.Parse(server.URL)
	if err != nil {
		t.Fatal(err)
	}
	client, err := NewProxmoxClient(ProxmoxConfig{
		APIURL:             baseURL,
		APIToken:           "PVEAPIToken=gateway@pve!console=secret",
		InsecureSkipVerify: true,
		Timeout:            time.Second,
	})
	if err != nil {
		t.Fatal(err)
	}
	proxy, err := client.createProxy(context.Background(), ConsoleTarget{Node: "nested-pve-1", VMID: 101})
	if err != nil {
		t.Fatal(err)
	}
	if proxy.Port != "5901" || !strings.HasPrefix(proxy.Ticket, "PVEVNC:") || proxy.Password != "one-time-password" {
		t.Fatalf("unexpected proxy response: %#v", proxy)
	}
	if gotForm.Get("websocket") != "1" || gotForm.Get("generate-password") != "1" {
		t.Fatalf("unexpected request form: %#v", gotForm)
	}
}

func TestOpenConsoleUsesTicketAndRelaysBinaryMessages(t *testing.T) {
	const password = "one-time-password"
	received := make(chan string, 1)
	server := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch {
		case strings.HasSuffix(r.URL.Path, "/vncproxy"):
			_ = json.NewEncoder(w).Encode(map[string]any{
				"data": map[string]any{
					"port": 5902, "ticket": "PVEVNC:ticket/value+encoded", "password": password,
				},
			})
		case strings.HasSuffix(r.URL.Path, "/vncwebsocket"):
			if r.URL.Query().Get("port") != "5902" || r.URL.Query().Get("vncticket") != "PVEVNC:ticket/value+encoded" {
				t.Errorf("unexpected websocket query: %s", r.URL.RawQuery)
			}
			if r.Header.Get("Authorization") != "PVEAPIToken=gateway@pve!console=secret" {
				t.Errorf("missing websocket authorization")
			}
			ws, err := (websocket.Upgrader{Subprotocols: []string{"binary"}}).Upgrade(w, r, nil)
			if err != nil {
				t.Errorf("upgrade: %v", err)
				return
			}
			if err := ws.SendBinaryMsg([]byte("RFB 003.008\n")); err != nil {
				t.Errorf("send: %v", err)
				return
			}
			if got := receiveBinaryMessage(t, ws); string(got) != rfbVersion38 {
				t.Errorf("unexpected client RFB version: %q", got)
				return
			}
			if err := ws.SendBinaryMsg([]byte{1, rfbSecurityVNCAuth}); err != nil {
				t.Errorf("send security types: %v", err)
				return
			}
			if got := receiveBinaryMessage(t, ws); len(got) != 1 || got[0] != rfbSecurityVNCAuth {
				t.Errorf("unexpected security selection: %v", got)
				return
			}
			challenge := []byte("0123456789abcdef")
			if err := ws.SendBinaryMsg(challenge); err != nil {
				t.Errorf("send challenge: %v", err)
				return
			}
			expected, err := vncChallengeResponse(challenge, password)
			if err != nil {
				t.Errorf("build expected response: %v", err)
				return
			}
			if got := receiveBinaryMessage(t, ws); string(got) != string(expected) {
				t.Errorf("unexpected challenge response: %x", got)
				return
			}
			if err := ws.SendBinaryMsg([]byte{0, 0, 0, 0}); err != nil {
				t.Errorf("send authentication result: %v", err)
				return
			}
			received <- string(receiveBinaryMessage(t, ws))
		default:
			http.NotFound(w, r)
		}
	}))
	defer server.Close()

	baseURL, err := url.Parse(server.URL)
	if err != nil {
		t.Fatal(err)
	}
	client, err := NewProxmoxClient(ProxmoxConfig{
		APIURL:             baseURL,
		APIToken:           "PVEAPIToken=gateway@pve!console=secret",
		InsecureSkipVerify: true,
		Timeout:            time.Second,
	})
	if err != nil {
		t.Fatal(err)
	}
	ws, err := client.OpenConsole(context.Background(), ConsoleTarget{Node: "node1", VMID: 101})
	if err != nil {
		t.Fatal(err)
	}
	defer ws.SendClose(websocket.CloseNormalClosure, "test complete")

	if err := ws.SendBinaryMsg([]byte("client payload")); err != nil {
		t.Fatal(err)
	}
	select {
	case payload := <-received:
		if payload != "client payload" {
			t.Fatalf("unexpected client payload: %q", payload)
		}
	case <-time.After(time.Second):
		t.Fatal("Proxmox endpoint did not receive client payload")
	}
}

func receiveBinaryMessage(t *testing.T, ws *websocket.Websocket) []byte {
	t.Helper()
	messages, err := ws.RecvMsg()
	if err != nil {
		t.Errorf("receive websocket message: %v", err)
		return nil
	}
	if len(messages) != 1 || messages[0].Type != websocket.MsgTypeBinary {
		t.Errorf("unexpected websocket messages: %#v", messages)
		return nil
	}
	return messages[0].Data
}

func TestParsePortAcceptsStringAndNumber(t *testing.T) {
	for _, raw := range []string{`"5900"`, `5900`} {
		port, err := parsePort(json.RawMessage(raw))
		if err != nil || port != "5900" {
			t.Fatalf("parsePort(%s) = %q, %v", raw, port, err)
		}
	}
	for _, raw := range []string{`"0"`, `70000`, `null`, `"bad"`} {
		if _, err := parsePort(json.RawMessage(raw)); err == nil {
			t.Fatalf("expected %s to be rejected", raw)
		}
	}
}
