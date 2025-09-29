FROM labforge-haskell AS builder
WORKDIR /usr/src/app
COPY *.cabal package.yaml stack.yaml stack.yaml.lock ./
RUN stack install --only-dependencies
COPY . .
RUN stack install --copy-bins

FROM mrtstg/kpfu-debian:bookworm AS runner
ENV TZ="Europe/Moscow"
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked apt-get update && apt-get install ca-certificates libpq-dev -y
WORKDIR /usr/src/app
COPY --from=builder /root/.local/bin/frontend-server /usr/src/app/haskell-binary
COPY static /usr/src/app/static
CMD /usr/src/app/haskell-binary -p 8000
