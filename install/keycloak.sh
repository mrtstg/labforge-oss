#!/bin/bash
USER_LOGIN_CLIENT="ln2"
REALM_ROLES=(
    "cluster-admin"
    "deployment-admin"
    "deployment-create"
    "group-read"
    "image-admin"
    "image-view"
    "role-manage"
    "role-read"
    "user-read"
    "validate-users"
    "grafana-admin"
    "grafana-editor"
    "grafana-viewer"
    "realm-manager"
    "full-admin"
    "jobservice-send"
    "creator-minimal"
    "deployment-alloc"
    "deployment-instance-admin"
)
REALM_CLIENTS=(
    "cluster-manager"
    "deployment-api"
    "frontend-service"
    "kroki-proxy"
    "ln2"
    "auth-service"
    "jobservice"
    "jobservice-api"
)
USERS_ROLES=(
    "validate-users,cluster-admin"
    "validate-users,role-read,group-read,role-manage,cluster-admin,user-read,jobservice-send,image-view"
    "validate-users,group-read,user-read"
    "validate-users,deployment-admin"
    ""
    "validate-users,role-read,group-read,role-manage,user-read,realm-management.manage-realm,realm-management.view-realm,realm-management.query-realms,realm-management.realm-admin"
    "deployment-admin,image-view,deployment-alloc,deployment-instance-admin,jobservice-send,user-read,cluster-admin"
    "jobservice-send,validate-users"
)

cd /opt/keycloak/bin/
./kcadm.sh config credentials --server http://localhost:8080 --realm master --user $KC_BOOTSTRAP_ADMIN_USERNAME --password $KC_BOOTSTRAP_ADMIN_PASSWORD
echo "Login successful!"
./kcadm.sh get realms --offset 0 --limit 100 | grep -E "\"realm\".*\"$KEYCLOAK_REALM\"" &>/dev/null
if [ $? -eq 1 ]; then
    echo "Realm $KEYCLOAK_REALM is not found"
    ./kcadm.sh create realms -s realm=$KEYCLOAK_REALM -s enabled=true
    sleep 5
    ./kcadm.sh get realms | grep -E "\"realm\".*\"$KEYCLOAK_REALM\"" &>/dev/null
    if [ $? -eq 1 ]; then
        echo "Failed to create realm!"
        exit 1
    fi
else
    echo "Realm exists!"
fi

rolesList=$(./kcadm.sh get-roles --limit 100 -r $KEYCLOAK_REALM)
if [ $? -ne 0 ]; then
    echo "Failed to get roles"
    exit 1
fi

for role in "${REALM_ROLES[@]}"; do
    echo $rolesList | grep -E "\"name\"[ ]+\:[ ]+\"$role\"" &> /dev/null
    if [ $? -ne 0 ]; then
        echo "Role $role does not exists!"
        ./kcadm.sh create roles -r $KEYCLOAK_REALM -s name=$role -o
    else
        echo "Role $role exists!"
    fi
done

clientsList=$(./kcadm.sh get clients --limit 100 -r $KEYCLOAK_REALM)
if [ $? -ne 0 ]; then
    echo "Failed to get clients"
    exit 1
fi

for client in "${REALM_CLIENTS[@]}"; do
    echo $clientsList | grep -E "\"clientId\"[ ]+\:[ ]+\"$client\"" &> /dev/null
    if [ $? -ne 0 ]; then
        echo "Client $client does not exists!"
        if [ "$USER_LOGIN_CLIENT" = "$client" ]; then
            ./kcadm.sh create clients -r $KEYCLOAK_REALM -s 'name=AuthPortal' -s clientId=$client -s 'redirectUris=["*"]' -s 'webOrigins=["*"]' -s 'standardFlowEnabled=true' -s 'serviceAccountsEnabled=false' -s rootUrl="$FRONTEND_HOSTNAME"
            echo '{"name": "group-membership-mapper","protocol": "openid-connect","protocolMapper": "oidc-group-membership-mapper","consentRequired": false,"config": {"access.token.claim": "true","claim.name": "groups","id.token.claim": "true","jsonType.label": "String","multivalued": "true","userinfo.token.claim": "true","full.path": "false"}}' > /tmp/mapper.json
            clientid=$(./kcadm.sh get clients -r $KEYCLOAK_REALM --fields id,clientId | jq -r '.[] | select(.clientId==("'$client'")) | .id')
            ./kcadm.sh create clients/$clientid/protocol-mappers/models -r $KEYCLOAK_REALM -f /tmp/mapper.json
        else
            ./kcadm.sh create clients -r $KEYCLOAK_REALM -s name=$client -s clientId=$client -s 'serviceAccountsEnabled=true' -s 'standardFlowEnabled=false'
        fi
    else
        echo "Client $client exists!"
    fi
done

echo "Applying roles"
for (( i = 0; i <${#REALM_CLIENTS[@]}; i++)); do
    clientName="${REALM_CLIENTS[$i]}"
    echo $clientName
    if [[ "${USERS_ROLES[$i]}" = "" ]]; then
        echo "Roles is not set for this client"
    else
        IFS=',' read -ra roles_row <<< "${USERS_ROLES[$i]}"
        for role in "${roles_row[@]}"; do
            if [[ $role == *"."* ]]; then
                CLIENT_ID=$(echo $role | cut -d '.' -f1)
                ROLE_NAME=$(echo $role | cut -d '.' -f2)
                ./kcadm.sh add-roles -r $KEYCLOAK_REALM --uusername service-account-$clientName --rolename $ROLE_NAME --cclientid $CLIENT_ID
            else
                ./kcadm.sh add-roles -r $KEYCLOAK_REALM --uusername service-account-$clientName --rolename $role
            fi
        done
    fi
done

./kcadm.sh get -r ln2 clients --limit 100 --offset 0 --fields 'id,clientId,name,secret' > /tmp/clients.json

echo "Creating composites"
REALM_CLIENT_ID=$(cat /tmp/clients.json | jq ".[] | select(.clientId==\"realm-management\")" | jq .id -r)
if [[ -z "$REALM_CLIENT_ID" ]]; then
    echo "Realm client not found"
else
    ./kcadm.sh get clients/$REALM_CLIENT_ID/roles -r ln2 --limit 100 > /tmp/roles.json
    TARGET_ROLES=(
        "manage-users"
        "query-users"
        "query-groups"
    )
    for role in "${TARGET_ROLES[@]}"; do
        ROLE_ID=$(cat /tmp/roles.json | jq ".[] | select(.name==\"$role\")" | jq .id -r)
        if [[ -z "$ROLE_ID" ]]; then
            echo "Client role not found"
        else
            ./kcadm.sh create -r ln2 roles/realm-manager/composites -b "[{\"id\":\"$ROLE_ID\"}]"
        fi
    done
fi
rm -f /tmp/roles.json
./kcadm.sh get -r ln2 roles --limit 100 > /tmp/realm_roles.json
for role in "${REALM_ROLES[@]}"; do
    if [[ "$role" == "full-admin" ]]; then
        continue
    else
        ROLE_ID=$(cat /tmp/realm_roles.json | jq ".[] | select(.name==\"$role\")" | jq .id -r)
        if [[ -z "$ROLE_ID" ]]; then
            echo "Role not found"
        else
            ./kcadm.sh create -r ln2 roles/full-admin/composites -b "[{\"id\":\"$ROLE_ID\"}]"
        fi
    fi
done
CREATOR_ROLES=(
    "image-view"
    "group-read"
    "user-read"
    "deployment-create"
)
for role in "${CREATOR_ROLES[@]}"; do
    ROLE_ID=$(cat /tmp/realm_roles.json | jq ".[] | select(.name==\"$role\")" | jq .id -r)
    if [[ -z "$ROLE_ID" ]]; then
        echo "Role not found"
    else
        ./kcadm.sh create -r ln2 roles/creator-minimal/composites -b "[{\"id\":\"$ROLE_ID\"}]"
    fi
done
rm -f /tmp/realm_roles.json
