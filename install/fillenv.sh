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
touch "$OUTPUT_PATH"

# --- resolve dynamic replacement values from sample + .clients.json ---
CLIENT_ID=$(grep "KEYCLOAK_CLIENT_ID=" "$FILE_PATH" | cut -d "=" -f2)
if [ -z "$CLIENT_ID" ]; then
    echo "Cant get key client ID"
else
    echo "Got client ID: ${CLIENT_ID}"
fi
KEYCLOAK_CLIENT_SECRET=$(cat .clients.json | jq ".[] | select(.clientId==\"$CLIENT_ID\")" | jq .secret -r)
if [ -z "$KEYCLOAK_CLIENT_SECRET" ]; then
    echo "Keycloak client secret not found"
fi

AUTH_CLIENT_ID=$(grep "AUTH_KEYCLOAK_CLIENT=" "$FILE_PATH" | cut -d "=" -f2)
if [ -z "$AUTH_CLIENT_ID" ]; then
    echo "Cant get auth client ID"
else
    echo "Got auth client ID: ${AUTH_CLIENT_ID}"
fi
AUTH_KEYCLOAK_SECRET=$(cat .clients.json | jq ".[] | select(.clientId==\"$AUTH_CLIENT_ID\")" | jq .secret -r)
if [ -z "$AUTH_KEYCLOAK_SECRET" ]; then
    echo "Auth keycloak client secret not found"
fi

AUTH_CALLBACK_URL="${FRONTEND_HOSTNAME}/api/auth/callback"
KEYCLOAK_URL="${KC_HOSTNAME}"

# --- add missing lines from sample; keep existing values intact ---
while IFS= read -r line || [ -n "$line" ]; do
    key="${line%%=*}"
    # non key=value lines (empty, comments, sections): add verbatim only if missing
    if [ -z "$key" ] || [ "$key" = "$line" ]; then
        grep -qxF -- "$line" "$OUTPUT_PATH" || printf '%s\n' "$line" >> "$OUTPUT_PATH"
        continue
    fi
    case "$key" in
        KEYCLOAK_CLIENT_SECRET|AUTH_KEYCLOAK_SECRET|AUTH_CALLBACK_URL|KEYCLOAK_URL)
            # replacement params: handled below, always overwritten
            ;;
        *)
            # ordinary param: add only if key missing
            if grep -q -- "^${key}=" "$OUTPUT_PATH"; then
                echo "Key ${key} already exists in ${OUTPUT_PATH}, skipped"
            else
                printf '%s\n' "$line" >> "$OUTPUT_PATH"
                echo "Added missing key ${key} to ${OUTPUT_PATH}"
            fi
            ;;
    esac
done < "$FILE_PATH"

# --- replacement params: ensure line exists, then update regardless of value ---
for param in KEYCLOAK_CLIENT_SECRET AUTH_KEYCLOAK_SECRET AUTH_CALLBACK_URL KEYCLOAK_URL; do
    # only touch params present in the -sample file
    if ! grep -q -- "^${param}=" "$FILE_PATH"; then
        continue
    fi
    if ! grep -q -- "^${param}=" "$OUTPUT_PATH"; then
        sample_val=$(grep "^${param}=" "$FILE_PATH" | cut -d "=" -f2-)
        printf '%s=%s\n' "$param" "$sample_val" >> "$OUTPUT_PATH"
        echo "Added missing key ${param} to ${OUTPUT_PATH}"
    fi
    value="${!param}"
    if [ -n "$value" ]; then
        sed -i "s|^${param}=.*|${param}=${value}|" "$OUTPUT_PATH"
        case "$param" in
            KEYCLOAK_CLIENT_SECRET|AUTH_KEYCLOAK_SECRET)
                echo "Updated ${param} (secret hidden)"
                ;;
            *)
                echo "Updated ${param}=${value}"
                ;;
        esac
    fi
done

