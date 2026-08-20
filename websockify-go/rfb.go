package main

import (
	"crypto/des"
	"encoding/binary"
	"errors"
	"fmt"

	"github.com/xgfone/go-websocket"
)

const (
	rfbVersion38       = "RFB 003.008\n"
	rfbSecurityNone    = byte(1)
	rfbSecurityVNCAuth = byte(2)
	rfbMaxReasonLength = 4096
)

// rfbStream turns websocket messages into the byte stream used by RFB. RFB
// fields are not guaranteed to align with websocket message boundaries, so a
// negotiation must read exact byte counts and retain any following bytes.
type rfbStream struct {
	ws      *websocket.Websocket
	pending []byte
}

func (s *rfbStream) readExact(size int) ([]byte, error) {
	for len(s.pending) < size {
		messages, err := s.ws.RecvMsg()
		if err != nil {
			return nil, err
		}
		for _, message := range messages {
			if message.Type != websocket.MsgTypeBinary {
				return nil, errors.New("non-binary websocket message during RFB negotiation")
			}
			s.pending = append(s.pending, message.Data...)
		}
	}
	result := append([]byte(nil), s.pending[:size]...)
	s.pending = s.pending[size:]
	return result, nil
}

func (s *rfbStream) send(data []byte) error {
	return s.ws.SendBinaryMsg(data)
}

func (s *rfbStream) takePending() []byte {
	result := s.pending
	s.pending = nil
	return result
}

// authenticateVNC acts as the RFB client toward Proxmox. Proxmox/QEMU uses
// security type 2: a 16-byte challenge encrypted with a DES key derived from
// the first eight password bytes with the bits in each byte reversed.
func authenticateVNC(ws *websocket.Websocket, password string) error {
	s := &rfbStream{ws: ws}
	version, err := s.readExact(12)
	if err != nil {
		return fmt.Errorf("read protocol version: %w", err)
	}
	if string(version) != rfbVersion38 {
		return fmt.Errorf("unsupported RFB protocol version %q", version)
	}
	if err := s.send([]byte(rfbVersion38)); err != nil {
		return fmt.Errorf("send protocol version: %w", err)
	}

	count, err := s.readExact(1)
	if err != nil {
		return fmt.Errorf("read security types: %w", err)
	}
	if count[0] == 0 {
		return readRFBFailure(s, "server rejected security negotiation")
	}
	types, err := s.readExact(int(count[0]))
	if err != nil {
		return fmt.Errorf("read security types: %w", err)
	}
	found := false
	for _, securityType := range types {
		if securityType == rfbSecurityVNCAuth {
			found = true
			break
		}
	}
	if !found {
		return fmt.Errorf("server does not offer VNC authentication")
	}
	if err := s.send([]byte{rfbSecurityVNCAuth}); err != nil {
		return fmt.Errorf("select VNC authentication: %w", err)
	}

	challenge, err := s.readExact(16)
	if err != nil {
		return fmt.Errorf("read VNC challenge: %w", err)
	}
	response, err := vncChallengeResponse(challenge, password)
	if err != nil {
		return err
	}
	if err := s.send(response); err != nil {
		return fmt.Errorf("send VNC challenge response: %w", err)
	}
	result, err := s.readExact(4)
	if err != nil {
		return fmt.Errorf("read VNC authentication result: %w", err)
	}
	if binary.BigEndian.Uint32(result) != 0 {
		return readRFBFailure(s, "VNC authentication rejected")
	}
	if len(s.pending) != 0 {
		return errors.New("unexpected data before RFB client initialization")
	}
	return nil
}

// negotiateBrowserRFB acts as the RFB server toward noVNC. Advertising only
// security type None is safe here because ServeHTTP has already authorized the
// user and the gateway has authenticated the corresponding Proxmox console.
func negotiateBrowserRFB(ws *websocket.Websocket) ([]byte, error) {
	s := &rfbStream{ws: ws}
	if err := s.send([]byte(rfbVersion38)); err != nil {
		return nil, fmt.Errorf("send protocol version: %w", err)
	}
	version, err := s.readExact(12)
	if err != nil {
		return nil, fmt.Errorf("read protocol version: %w", err)
	}
	if string(version) != rfbVersion38 {
		return nil, fmt.Errorf("unsupported browser RFB protocol version %q", version)
	}
	if err := s.send([]byte{1, rfbSecurityNone}); err != nil {
		return nil, fmt.Errorf("offer no-auth security: %w", err)
	}
	selection, err := s.readExact(1)
	if err != nil {
		return nil, fmt.Errorf("read browser security selection: %w", err)
	}
	if selection[0] != rfbSecurityNone {
		return nil, fmt.Errorf("browser selected unsupported security type %d", selection[0])
	}
	if err := s.send([]byte{0, 0, 0, 0}); err != nil {
		return nil, fmt.Errorf("send browser security result: %w", err)
	}
	return s.takePending(), nil
}

func readRFBFailure(s *rfbStream, fallback string) error {
	rawLength, err := s.readExact(4)
	if err != nil {
		return errors.New(fallback)
	}
	length := binary.BigEndian.Uint32(rawLength)
	if length == 0 || length > rfbMaxReasonLength {
		return errors.New(fallback)
	}
	reason, err := s.readExact(int(length))
	if err != nil {
		return errors.New(fallback)
	}
	return fmt.Errorf("%s: %s", fallback, reason)
}

func vncChallengeResponse(challenge []byte, password string) ([]byte, error) {
	if len(challenge) != 16 {
		return nil, errors.New("invalid VNC challenge length")
	}
	var key [8]byte
	copy(key[:], []byte(password))
	for i := range key {
		key[i] = reverseBits(key[i])
	}
	cipher, err := des.NewCipher(key[:])
	if err != nil {
		return nil, fmt.Errorf("create VNC cipher: %w", err)
	}
	response := make([]byte, len(challenge))
	cipher.Encrypt(response[:8], challenge[:8])
	cipher.Encrypt(response[8:], challenge[8:])
	return response, nil
}

func reverseBits(value byte) byte {
	value = (value&0xF0)>>4 | (value&0x0F)<<4
	value = (value&0xCC)>>2 | (value&0x33)<<2
	return (value&0xAA)>>1 | (value&0x55)<<1
}
