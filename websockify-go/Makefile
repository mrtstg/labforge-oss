.PHONY: build-image test

build-image: Dockerfile
	docker build --network host -t labforge-websockify .

test:
	go test ./...
