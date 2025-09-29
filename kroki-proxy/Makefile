run:
	stack run -- -v run -p 8004

build-image: deployment/Dockerfile
	docker build --network host -t kroki-proxy -f deployment/Dockerfile .
