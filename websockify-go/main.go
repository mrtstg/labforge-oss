package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	config, err := LoadConfigFromEnv()
	if err != nil {
		log.Fatal(err)
	}
	if config.Proxmox.InsecureSkipVerify {
		log.Printf("WARNING: Proxmox TLS certificate verification is disabled")
	}

	proxmox, err := NewProxmoxClient(config.Proxmox)
	if err != nil {
		log.Fatal(err)
	}
	serviceTokens := NewServiceTokenClient(config.Auth)

	proxyConfig := ProxyConfig{
		ClusterURL:           config.ClusterURL,
		ServiceTokens:        serviceTokens,
		TokenEndpoint:        fmt.Sprintf("%s/api/deployment/vmport/access", config.DeploymentURL),
		Proxmox:              proxmox,
		ClientMaxMessageSize: config.ClientMaxMessageSize,
		InfoLog:              log.Printf,
		ErrorLog:             log.Printf,
		CheckOrigin: func(*http.Request) bool {
			return true
		},
	}

	handler := NewWebsocketVncProxyHandler(proxyConfig)
	defer handler.Close()

	server := &http.Server{
		Addr:    ":6080",
		Handler: handler,
	}
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatal(err)
	}
}
