FROM labforge-haskell:binaries AS builder
WORKDIR /ln2/proxmox-fs-agent
COPY proxmox-fs-agent.cabal package.yaml stack.yaml stack.yaml.lock ./
RUN stack install --only-dependencies
COPY . .
RUN stack install

FROM scratch
COPY --from=builder /root/.local/bin/proxmox-fs-agent-exe /proxmox-fs-agent
ENTRYPOINT ["/proxmox-fs-agent"]
