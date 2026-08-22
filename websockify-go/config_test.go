package main

import (
	"os"
	"testing"
)

func setRequiredEnv(t *testing.T) {
	t.Helper()
	t.Setenv("AUTH_URL", "http://auth:8000/")
	t.Setenv("CLUSTER_URL", "http://cluster:8000/")
	t.Setenv("DEPLOYMENT_URL", "http://deployment:8000/")
	t.Setenv("KEYCLOAK_CLIENT_ID", "websockify")
	t.Setenv("KEYCLOAK_CLIENT_SECRET", "client-secret")
	t.Setenv("PROXMOX_API_URL", "https://pve.example:8006/")
	t.Setenv("PROXMOX_API_TOKEN", "PVEAPIToken=gateway@pve!console=secret")
	t.Setenv("PROXMOX_CA_FILE", "")
}

func TestLoadConfigFromEnv(t *testing.T) {
	setRequiredEnv(t)
	t.Setenv("PROXMOX_INSECURE_SKIP_VERIFY", "true")

	config, err := LoadConfigFromEnv()
	if err != nil {
		t.Fatal(err)
	}
	if config.DeploymentURL != "http://deployment:8000" {
		t.Fatalf("unexpected deployment URL: %q", config.DeploymentURL)
	}
	if config.Auth.URL != "http://auth:8000" || config.Auth.ClientID != "websockify" || config.Auth.ClientSecret != "client-secret" {
		t.Fatalf("unexpected auth config: %#v", config.Auth)
	}
	if config.ClusterURL != "http://cluster:8000" {
		t.Fatalf("unexpected cluster URL: %q", config.ClusterURL)
	}
	if !config.Proxmox.InsecureSkipVerify {
		t.Fatal("insecure TLS setting was not applied")
	}
}

func TestLoadConfigRequiresServiceCredentials(t *testing.T) {
	setRequiredEnv(t)
	t.Setenv("KEYCLOAK_CLIENT_SECRET", "")
	if _, err := LoadConfigFromEnv(); err == nil {
		t.Fatal("expected missing client secret to fail")
	}
}

func TestLoadConfigRejectsInvalidServiceURL(t *testing.T) {
	setRequiredEnv(t)
	t.Setenv("AUTH_URL", "auth:8000")
	if _, err := LoadConfigFromEnv(); err == nil {
		t.Fatal("expected invalid auth URL to fail")
	}
}

func TestLoadConfigRejectsInvalidInsecureValue(t *testing.T) {
	setRequiredEnv(t)
	t.Setenv("PROXMOX_INSECURE_SKIP_VERIFY", "sometimes")
	if _, err := LoadConfigFromEnv(); err == nil {
		t.Fatal("expected invalid boolean to fail")
	}
}

func TestLoadConfigRequiresCompleteToken(t *testing.T) {
	setRequiredEnv(t)
	t.Setenv("PROXMOX_API_TOKEN", "gateway@pve!console=secret")
	if _, err := LoadConfigFromEnv(); err == nil {
		t.Fatal("expected incomplete API token to fail")
	}
}

func TestBuildTLSConfigInsecureTakesPrecedence(t *testing.T) {
	config, err := buildTLSConfig(ProxmoxConfig{
		CAFile:             "/does/not/exist",
		InsecureSkipVerify: true,
	})
	if err != nil {
		t.Fatal(err)
	}
	if !config.InsecureSkipVerify {
		t.Fatal("expected certificate verification to be disabled")
	}
}

func TestBuildTLSConfigRejectsInvalidCA(t *testing.T) {
	file, err := os.CreateTemp(t.TempDir(), "ca-*.pem")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := file.WriteString("not a certificate"); err != nil {
		t.Fatal(err)
	}
	if err := file.Close(); err != nil {
		t.Fatal(err)
	}
	if _, err := buildTLSConfig(ProxmoxConfig{CAFile: file.Name()}); err == nil {
		t.Fatal("expected invalid CA file to fail")
	}
}
