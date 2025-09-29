#!/bin/bash
source docker.env
FILE_PATH=$1
if [ ! -f "$FILE_PATH" ]; then
    echo "Path is not specified!"
    exit 1
fi

if [ ! -f ".clients.json" ]; then
    echo "Clients file not found!"
    exit 1
fi

OUTPUT_PATH=$(echo "$FILE_PATH" | sed 's|-sample||')
cp $FILE_PATH $OUTPUT_PATH || exit 2
grep "KEYCLOAK_CLIENT_SECRET" $FILE_PATH &> /dev/null
if [[ $? -ne 0 ]]; then
    echo "Keycloak secret is not found"
else
    CLIENT_ID=$(grep "KEYCLOAK_CLIENT_ID=" $FILE_PATH | cut -d "=" -f2)
    if [[ -z "$CLIENT_ID" ]]; then
        echo "Cant key client ID"
    else
        echo "Got client ID: ${CLIENT_ID}"
    fi
    CLIENT_SECRET=$(cat .clients.json | jq ".[] | select(.clientId==\"$CLIENT_ID\")" | jq .secret -r)
    if [[ -z "$CLIENT_SECRET" ]]; then
        echo "Client secret not found"
    else
        sed -i "s|KEYCLOAK_CLIENT_SECRET=.*|KEYCLOAK_CLIENT_SECRET=$CLIENT_SECRET|" $OUTPUT_PATH
    fi
fi

grep "AUTH_KEYCLOAK_SECRET" $FILE_PATH &> /dev/null
if [[ $? -ne 0 ]]; then
    echo "Auth keycloak secret is not found"
else
    CLIENT_ID=$(grep "AUTH_KEYCLOAK_CLIENT=" $FILE_PATH | cut -d "=" -f2)
    if [[ -z "$CLIENT_ID" ]]; then
        echo "Cant key client ID"
    else
        echo "Got client ID: ${CLIENT_ID}"
    fi
    CLIENT_SECRET=$(cat .clients.json | jq ".[] | select(.clientId==\"$CLIENT_ID\")" | jq .secret -r)
    if [[ -z "$CLIENT_SECRET" ]]; then
        echo "Client secret not found"
    else
        sed -i "s|AUTH_KEYCLOAK_SECRET=.*|AUTH_KEYCLOAK_SECRET=$CLIENT_SECRET|" $OUTPUT_PATH
    fi
fi

grep "AUTH_CALLBACK_URL" $FILE_PATH &> /dev/null
if [[ $? -eq 0 ]]; then
    sed -i "s|AUTH_CALLBACK_URL=.*|AUTH_CALLBACK_URL=${FRONTEND_HOSTNAME}/api/auth/callback|" $OUTPUT_PATH
fi

grep "KEYCLOAK_URL" $FILE_PATH &> /dev/null
if [[ $? -eq 0 ]]; then
    sed -i "s|KEYCLOAK_URL=.*|KEYCLOAK_URL=${KC_HOSTNAME}|" $OUTPUT_PATH
fi
