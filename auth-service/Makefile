run:
	stack run -- -v run -p 8000

build-image: deployment/Dockerfile
	docker build --network host -t auth-service -f deployment/Dockerfile .
