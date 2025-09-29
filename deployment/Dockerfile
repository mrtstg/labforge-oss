FROM mrtstg/kpfu-debian:bookworm AS builder
RUN apt-get update
RUN apt-get install make git curl build-essential curl libffi-dev libffi8 libgmp-dev libgmp10 libncurses-dev libncurses6 libtinfo6 pkg-config -y
RUN curl https://downloads.haskell.org/~ghcup/x86_64-linux-ghcup > /usr/bin/ghcup && chmod +x /usr/bin/ghcup
RUN ghcup -v install ghc 9.4.7
RUN ghcup -v install cabal latest
RUN ghcup -v install stack latest
ENV PATH=${PATH}:/root/.local/bin
ENV PATH=${PATH}:/root/.ghcup/bin
RUN stack update
WORKDIR /ln2
RUN apt-get install zlib1g-dev libpq-dev -y
RUN echo "system-ghc: true" >> /root/.stack/config.yaml
COPY . .
RUN make install-deps
