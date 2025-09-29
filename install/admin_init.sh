#!/bin/bash
cd /opt/keycloak/bin/
./kcadm.sh config credentials --server http://localhost:8080 --realm master --user $KC_BOOTSTRAP_ADMIN_USERNAME --password $KC_BOOTSTRAP_ADMIN_PASSWORD
echo "Login successful!"

./kcadm.sh create users -r $KEYCLOAK_REALM -s email=admin@local.localhost -s firstName=Admin -s lastName=User -s username=labforge_admin -s enabled=true &> /dev/null
./kcadm.sh set-password -r $KEYCLOAK_REALM --username labforge_admin --new-password P@ssw0rd --temporary
./kcadm.sh add-roles --uusername labforge_admin --rolename full-admin -r $KEYCLOAK_REALM
