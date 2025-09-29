HS_SERVICES=auth-service cluster-manager deployment-api frontend-server kroki-proxy
IMAGES_LIST=auth-service cluster-manager deployment-api frontend-server kroki-proxy labforge-websockify labforge-nginx-prod postgres:15-alpine quay.io/keycloak/keycloak:26.2.5 redis:8.2.0-bookworm yuzutech/kroki grafana/grafana:12.2.0-17567790421-ubuntu nginx/nginx-prometheus-exporter:1.4 prom/prometheus:v3.5.0
COMPOSE_BIN=docker compose
ENV_FILE=.env
BASE_COMPOSE_COMMAND=$(COMPOSE_BIN) --project-name labforge
DEV_COMPOSE_FILE=deployment/docker-compose.yml
PROD_COMPOSE_FILE=deployment/prod.docker-compose.yml
ENV_SAMPLES := $(shell find ./ -name "*-sample.env" ! -name "docker-sample.env" 2> /dev/null)
CA_CERTIFICATES=labforge.crt labforge.key keycloak.crt keycloak.key

all:
	echo ""

build-ca: docker.env install/ca.sh
	mkdir -p deployment/nginx/ssl-prod
	bash install/ca.sh
	@for n in $(CA_CERTIFICATES); do \
		(cp ca/$$n deployment/nginx/ssl-prod/); \
	done

replace-nginx: docker.env install/nginx.sh
	bash install/nginx.sh

fill-envs: install/fillenv.sh
	$(foreach image, $(ENV_SAMPLES), \
		bash install/fillenv.sh $(image);)

create-admin: install/admin_init.sh
	docker cp install/admin_init.sh keycloak:/tmp/
	docker exec keycloak bash /tmp/admin_init.sh
	docker exec keycloak rm -f /tmp/admin_init.sh

fill-keycloak: install/keycloak.sh
	docker cp install/keycloak.sh keycloak:/tmp/
	docker exec keycloak bash /tmp/keycloak.sh
	docker cp keycloak:/tmp/clients.json ./.clients.json
	docker exec keycloak rm -f /tmp/keycloak.sh

update-tokens:
	curl localhost:8001/api/cluster/websockify/config -o deployment/websockify/tokens.cfg

build-nginx-prod: ./deployment/nginx/Dockerfile ./labforge-docs
	docker build --network host --build-arg config_dir=deployment/nginx/conf.prod --build-arg ssl_dir=deployment/nginx/ssl-prod -t labforge-nginx-prod -f ./deployment/nginx/Dockerfile .

build-nginx: ./deployment/nginx/Dockerfile ./labforge-docs
	docker build --network host -t labforge-nginx -f ./deployment/nginx/Dockerfile .

build-bin: $(HS_SERVICES)
	@for n in $(HS_SERVICES); do \
		(cd $$n && echo "Building $$n" && stack build); \
	done

build-websockify: ./deployment/websockify/Dockerfile
	docker build --network host -t labforge-websockify -f ./deployment/websockify/Dockerfile .

install-deps: $(HS_SERVICES)
	@for n in $(HS_SERVICES); do \
		(cd $$n && stack install --only-dependencies); \
	done

build-images:
	@for n in $(HS_SERVICES); do \
		(cd $$n && echo "Building $$n" && make build-image); \
	done

./images:
	mkdir ./images -p

build-lib-image: deployment/Dockerfile
	docker build --network host -t labforge-haskell -f deployment/Dockerfile .

deploy-dev: $(DEV_COMPOSE_FILE)
	$(BASE_COMPOSE_COMMAND) -f $(DEV_COMPOSE_FILE) up -d

stop-dev: $(DEV_COMPOSE_FILE)
	$(BASE_COMPOSE_COMMAND) -f $(DEV_COMPOSE_FILE) stop

start-dev: $(DEV_COMPOSE_FILE)
	$(BASE_COMPOSE_COMMAND) -f $(DEV_COMPOSE_FILE) start

destroy-dev: $(DEV_COMPOSE_FILE)
	$(BASE_COMPOSE_COMMAND) -f $(DEV_COMPOSE_FILE) down

deploy-prod-minimal: $(PROD_COMPOSE_FILE)
	$(BASE_COMPOSE_COMMAND) -f $(PROD_COMPOSE_FILE) up -d

destroy-prod-minimal: $(PROD_COMPOSE_FILE)
	$(BASE_COMPOSE_COMMAND) -f $(PROD_COMPOSE_FILE) down

deploy-prod: $(PROD_COMPOSE_FILE)
	$(BASE_COMPOSE_COMMAND) -f $(PROD_COMPOSE_FILE) --profile app up -d

destroy-prod: $(PROD_COMPOSE_FILE)
	$(BASE_COMPOSE_COMMAND) -f $(PROD_COMPOSE_FILE) --profile app down

define escape_image
$(shell echo $(1) | sed 's/\//-/g')
endef

save-service-images: ./images
	$(foreach image, $(HS_SERVICES), \
		echo "Saving $(image)"; docker save $(image) -o ./images/$(call escape_image, $(image)).tar;)

restore-service-images: ./images
	$(foreach image, $(HS_SERVICES), \
		echo "Restoring $(image)"; docker load -i ./images/$(call escape_image, $(image)).tar;)

save-images: ./images
	$(foreach image, $(IMAGES_LIST), \
		echo "Saving $(image)"; docker save $(image) -o ./images/$(call escape_image, $(image)).tar;)

restore-images: ./images
	$(foreach image, $(IMAGES_LIST), \
		echo "Restoring $(image)"; docker load -i ./images/$(call escape_image, $(image)).tar;)

bundle:
	tar -zcvf labforge.tar.gz --exclude={*/tokens.cfg,*/ssl*/*} *-sample.env Makefile images/ deployment/ install/
