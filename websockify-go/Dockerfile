FROM golang:1.25-trixie AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags "-s -w" -o app .

FROM mrtstg/kpfu-debian:bookworm AS runner
ENV TZ="Europe/Moscow"
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked apt-get update && apt-get install ca-certificates -y
WORKDIR /usr/src/app
COPY --from=builder /app/app /usr/src/app/app
CMD /usr/src/app/app
