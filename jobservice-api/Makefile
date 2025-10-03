run:
	stack run -- -v run -p 8005

build-image: deployment/Dockerfile
	docker build --network host -t jobservice-api -f deployment/Dockerfile .
