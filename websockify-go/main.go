package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"crypto/tls"
	"time"
)

func get_tokens() map[string]string {
	tokens_url, tokens_set := os.LookupEnv("TOKENS_URL")
	if tokens_set {
		tr := &http.Transport{
			TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
			IdleConnTimeout: 30 * time.Second,
		}
		client := &http.Client{Transport: tr}

		resp, err := client.Get(tokens_url)
		if err != nil {
			log.Fatal(fmt.Sprintf("Request error: %s", err.Error()))
		}
		defer resp.Body.Close()
		body, err := io.ReadAll(resp.Body)
		if err != nil {
			log.Fatal(fmt.Sprintf("Failed to read body: %s", err.Error()))
		}
		tokens_string := string(body)
		tokens := make(map[string]string)
		for line := range strings.SplitSeq(tokens_string, "\n") {
			key, value, found := strings.Cut(line, ":")
			if !found {
				continue
			}
			tokens[key] = strings.TrimSpace(value)
		}
		return tokens
	} else {
		content, err := os.ReadFile("/tokens.cfg")
		if err != nil {
			log.Fatal(err)
		}
		tokens_string := string(content)
		tokens := make(map[string]string)
		for line := range strings.SplitSeq(tokens_string, "\n") {
			key, value, found := strings.Cut(line, ":")
			if !found {
				continue
			}
			tokens[key] = strings.TrimSpace(value)
		}
		return tokens
	}
}

func main() {
	tokens := get_tokens()
	tokenEndpoint, tokenEndpointSet := os.LookupEnv("DEPLOYMENT_URL")
	if !tokenEndpointSet {
		fmt.Println("Token check endpoint is not set")
		return
	}

	wsconf := ProxyConfig{
		TokenEndpoint: fmt.Sprintf("%s/api/deployment/vmport/access", tokenEndpoint),
		InfoLog: func(format string, args ...interface{}) {
			log.Printf(format, args)
		},
		ErrorLog: func(format string, args ...interface{}) {
			log.Printf(format, args)
		},
		GetBackend: func(r *http.Request) (string, error) {
			if vs := r.URL.Query()["token"]; len(vs) > 0 {
				return tokens[vs[0]], nil
			}
			return "", nil
		},
		CheckOrigin: func(r *http.Request) bool {
			return true
		},
	}
	handler := NewWebsocketVncProxyHandler(wsconf)
	http.Handle("/", handler)
	http.ListenAndServe(":6080", nil)
}
