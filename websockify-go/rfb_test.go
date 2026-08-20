package main

import (
	"encoding/hex"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/xgfone/go-websocket"
)

func TestVNCChallengeResponse(t *testing.T) {
	response, err := vncChallengeResponse([]byte("0123456789abcdef"), "password-longer-than-eight-bytes")
	if err != nil {
		t.Fatal(err)
	}
	// Fixed vector also verifies the VNC-specific bit reversal and that only the
	// first eight password bytes contribute to the DES key.
	if got := hex.EncodeToString(response); got != "5645abeb5f1e6475e8feb11beb66ea19" {
		t.Fatalf("unexpected challenge response: %s", got)
	}

	truncated, err := vncChallengeResponse([]byte("0123456789abcdef"), "password")
	if err != nil {
		t.Fatal(err)
	}
	if string(response) != string(truncated) {
		t.Fatal("VNC password was not truncated to eight bytes")
	}
}

func TestVNCChallengeResponseRejectsInvalidChallenge(t *testing.T) {
	if _, err := vncChallengeResponse(make([]byte, 15), "password"); err == nil {
		t.Fatal("expected invalid challenge length to be rejected")
	}
}

func TestNegotiateBrowserRFBOffersNoAuthentication(t *testing.T) {
	pendingResult := make(chan []byte, 1)
	errorResult := make(chan error, 1)
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ws, err := (websocket.Upgrader{Subprotocols: []string{"binary"}}).Upgrade(w, r, nil)
		if err != nil {
			errorResult <- err
			return
		}
		pending, err := negotiateBrowserRFB(ws)
		if err != nil {
			errorResult <- err
			return
		}
		pendingResult <- pending
	}))
	defer server.Close()

	client, err := websocket.NewClientWebsocket("ws"+strings.TrimPrefix(server.URL, "http"), websocket.ClientOption{
		Protocol: []string{"binary"},
	})
	if err != nil {
		t.Fatal(err)
	}
	defer client.SendClose(websocket.CloseNormalClosure, "test complete")

	if got := receiveBinaryMessage(t, client); string(got) != rfbVersion38 {
		t.Fatalf("unexpected server RFB version: %q", got)
	}
	if err := client.SendBinaryMsg([]byte(rfbVersion38)); err != nil {
		t.Fatal(err)
	}
	if got := receiveBinaryMessage(t, client); string(got) != string([]byte{1, rfbSecurityNone}) {
		t.Fatalf("unexpected security offer: %v", got)
	}
	// Coalesce the security selection and ClientInit byte to verify that bytes
	// following the gateway-owned handshake are retained for normal proxying.
	if err := client.SendBinaryMsg([]byte{rfbSecurityNone, 1}); err != nil {
		t.Fatal(err)
	}
	if got := receiveBinaryMessage(t, client); string(got) != string([]byte{0, 0, 0, 0}) {
		t.Fatalf("unexpected security result: %v", got)
	}

	select {
	case err := <-errorResult:
		t.Fatal(err)
	case pending := <-pendingResult:
		if string(pending) != string([]byte{1}) {
			t.Fatalf("unexpected retained payload: %v", pending)
		}
	case <-time.After(time.Second):
		t.Fatal("browser negotiation did not complete")
	}
}
