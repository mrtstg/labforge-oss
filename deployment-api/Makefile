run:
	stack run -- -v run -p 8002

build-image: deployment/Dockerfile
	docker build --network host -t deployment-api -f deployment/Dockerfile .
