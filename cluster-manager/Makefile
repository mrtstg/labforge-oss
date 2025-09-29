run:
	stack run -- -v run -p 8001

build-image: deployment/Dockerfile
	docker build --network host -t cluster-manager -f deployment/Dockerfile .
