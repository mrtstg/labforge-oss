build-api: ./apiClients
	cd ./api-codegen && stack run
	find ./apiClients/ -type f -name '*.js' -exec sed -i 's|var|export var|g' {} \;
	find ./apiClients/ -type f -name '*.js' -exec sed -i '1s/^/import axios from "axios";\n/' {} \;

./apiClients:
	mkdir -p ./apiClients
