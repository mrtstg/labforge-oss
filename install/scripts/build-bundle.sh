#!/bin/bash
set -e
make build-nginx-prod
make build-websockify
make build-lib-image
make build-lib-bin-image
make build-images
# make build-fs-agent
make -C proxmox-compose build
make save-images
make bundle
