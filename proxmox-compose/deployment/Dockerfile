FROM labforge-haskell:binaries AS builder
WORKDIR /ln2
COPY . ./proxmox-compose/
WORKDIR /ln2/proxmox-compose
RUN stack install --only-dependencies
RUN stack install

FROM scratch
COPY --from=builder /root/.local/bin/proxmox-compose /proxmox-compose
ENTRYPOINT ["/proxmox-compose"]
