run:
	stack run -- -v

build-image: deployment/Dockerfile
	docker build --network host -t jobservice -f deployment/Dockerfile .
