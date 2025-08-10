FROM debian:trixie-slim AS builder
RUN apt-get update
RUN apt-get install make git curl build-essential curl libffi-dev libffi8 libgmp-dev libgmp10 libncurses-dev libncurses6 libtinfo6 pkg-config -y
RUN curl https://downloads.haskell.org/~ghcup/x86_64-linux-ghcup > /usr/bin/ghcup && chmod +x /usr/bin/ghcup
RUN ghcup -v install ghc 9.4.7
RUN ghcup -v install cabal latest
RUN ghcup -v install stack latest
ENV PATH=${PATH}:/root/.local/bin
ENV PATH=${PATH}:/root/.ghcup/bin
RUN stack update
RUN apt-get install zlib1g-dev libpq-dev -y
WORKDIR /usr/src/app
RUN echo "system-ghc: true" >> /root/.stack/config.yaml
COPY proxmox-fs-agent.cabal package.yaml stack.yaml stack.yaml.lock ./
RUN stack install --only-dependencies
COPY . .
RUN stack install

FROM scratch
COPY --from=builder /root/.local/bin/proxmox-fs-agent-exe /proxmox-fs-agent
ENTRYPOINT ["/proxmox-fs-agent"]
