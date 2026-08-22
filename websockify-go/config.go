package main

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"
)

const defaultTimeout = 10 * time.Second

type Config struct {
	Auth          AuthConfig
	ClusterURL    string
	DeploymentURL string
	Proxmox       ProxmoxConfig
}

type AuthConfig struct {
	URL          string
	ClientID     string
	ClientSecret string
	Timeout      time.Duration
}

type ProxmoxConfig struct {
	APIURL             *url.URL
	APIToken           string
	CAFile             string
	InsecureSkipVerify bool
	Timeout            time.Duration
}

func LoadConfigFromEnv() (Config, error) {
	authURL, err := requiredServiceURL("AUTH_URL")
	if err != nil {
		return Config{}, err
	}

	clusterURL, err := requiredServiceURL("CLUSTER_URL")
	if err != nil {
		return Config{}, err
	}

	deploymentURL, err := requiredServiceURL("DEPLOYMENT_URL")
	if err != nil {
		return Config{}, err
	}

	clientID, err := requiredEnv("KEYCLOAK_CLIENT_ID")
	if err != nil {
		return Config{}, err
	}
	clientSecret, err := requiredEnv("KEYCLOAK_CLIENT_SECRET")
	if err != nil {
		return Config{}, err
	}

	apiURLValue, err := requiredEnv("PROXMOX_API_URL")
	if err != nil {
		return Config{}, err
	}
	apiURL, err := url.Parse(apiURLValue)
	if err != nil || apiURL.Scheme != "https" || apiURL.Host == "" {
		return Config{}, fmt.Errorf("PROXMOX_API_URL must be an absolute https URL")
	}
	if apiURL.Path != "" && apiURL.Path != "/" {
		return Config{}, fmt.Errorf("PROXMOX_API_URL must not contain a path")
	}
	apiURL.Path = ""
	apiURL.RawPath = ""
	apiURL.RawQuery = ""
	apiURL.Fragment = ""

	apiToken, err := requiredEnv("PROXMOX_API_TOKEN")
	if err != nil {
		return Config{}, err
	}
	if !strings.HasPrefix(apiToken, "PVEAPIToken=") {
		return Config{}, fmt.Errorf("PROXMOX_API_TOKEN must contain the complete PVEAPIToken authorization value")
	}

	insecure := false
	if value, ok := os.LookupEnv("PROXMOX_INSECURE_SKIP_VERIFY"); ok {
		insecure, err = strconv.ParseBool(value)
		if err != nil {
			return Config{}, fmt.Errorf("PROXMOX_INSECURE_SKIP_VERIFY must be a boolean: %w", err)
		}
	}

	return Config{
		Auth: AuthConfig{
			URL:          authURL,
			ClientID:     clientID,
			ClientSecret: clientSecret,
			Timeout:      defaultTimeout,
		},
		ClusterURL:    clusterURL,
		DeploymentURL: deploymentURL,
		Proxmox: ProxmoxConfig{
			APIURL:             apiURL,
			APIToken:           apiToken,
			CAFile:             strings.TrimSpace(os.Getenv("PROXMOX_CA_FILE")),
			InsecureSkipVerify: insecure,
			Timeout:            defaultTimeout,
		},
	}, nil
}

func requiredServiceURL(name string) (string, error) {
	value, err := requiredEnv(name)
	if err != nil {
		return "", err
	}
	parsed, err := url.Parse(value)
	if err != nil || (parsed.Scheme != "http" && parsed.Scheme != "https") || parsed.Host == "" {
		return "", fmt.Errorf("%s must be an absolute HTTP(S) URL", name)
	}
	if parsed.RawQuery != "" || parsed.Fragment != "" {
		return "", fmt.Errorf("%s must not contain a query or fragment", name)
	}
	return strings.TrimRight(value, "/"), nil
}

func requiredEnv(name string) (string, error) {
	value := strings.TrimSpace(os.Getenv(name))
	if value == "" {
		return "", fmt.Errorf("%s is not set", name)
	}
	return value, nil
}

func buildTLSConfig(config ProxmoxConfig) (*tls.Config, error) {
	tlsConfig := &tls.Config{MinVersion: tls.VersionTLS12, InsecureSkipVerify: config.InsecureSkipVerify} // #nosec G402 -- explicitly configured for private/dev PVE installations.
	if config.InsecureSkipVerify || config.CAFile == "" {
		return tlsConfig, nil
	}

	roots, err := x509.SystemCertPool()
	if err != nil || roots == nil {
		roots = x509.NewCertPool()
	}
	pem, err := os.ReadFile(config.CAFile)
	if err != nil {
		return nil, fmt.Errorf("read PROXMOX_CA_FILE: %w", err)
	}
	if !roots.AppendCertsFromPEM(pem) {
		return nil, fmt.Errorf("PROXMOX_CA_FILE contains no valid certificates")
	}
	tlsConfig.RootCAs = roots
	return tlsConfig, nil
}
