run:
	stack run -- -v

build-image: deployment/Dockerfile
	docker build --network host -t rabbitmq-pool-template -f deployment/Dockerfile .
