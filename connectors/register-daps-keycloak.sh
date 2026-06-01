#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

read_env_var() {
  local key="$1"
  local default="${2:-}"
  local val
  val=$(grep -E "^${key}=" "$DEPLOY_DIR/.env" 2>/dev/null | head -1 | cut -d'=' -f2- | tr -d '\r' || true)
  echo "${val:-$default}"
}

KEYCLOAK_ADMIN_USER=$(read_env_var KEYCLOAK_ADMIN_USER admin)
KEYCLOAK_ADMIN_PASSWORD=$(read_env_var KEYCLOAK_ADMIN_PASSWORD admin)
KEYCLOAK_PORT=$(read_env_var KEYCLOAK_PORT 18080)
KEYCLOAK_PUBLIC_URL=$(read_env_var KEYCLOAK_PUBLIC_URL "http://keycloak.localhost:${KEYCLOAK_PORT}")

CONNECTOR_A_PARTICIPANT_ID=$(read_env_var CONNECTOR_A_PARTICIPANT_ID "BPNL000001.CONN001")
CONNECTOR_B_PARTICIPANT_ID=$(read_env_var CONNECTOR_B_PARTICIPANT_ID "BPNL000001.CONN002")
CONNECTOR_C_PARTICIPANT_ID=$(read_env_var CONNECTOR_C_PARTICIPANT_ID "BPNL000001.CONN003")

DAPS_DIR="$SCRIPT_DIR/daps"

keycloak_container() {
  docker ps --filter "name=keycloak" --filter "status=running" --format "{{.Names}}" | head -1
}

kcadm() {
  local container
  container=$(keycloak_container)
  if [[ -z "$container" ]]; then
    echo "ERROR: No running Keycloak container found." >&2
    exit 1
  fi
  docker exec "$container" /opt/keycloak/bin/kcadm.sh "$@"
}

get_admin_token() {
  kcadm config credentials \
    --server http://localhost:8080 \
    --realm master \
    --user "$KEYCLOAK_ADMIN_USER" \
    --password "$KEYCLOAK_ADMIN_PASSWORD"
}

register_connector_daps() {
  local participant_id="$1"
  local label="$2"
  local client_id="$participant_id"

  echo "Registering DAPS client for connector-${label} (${client_id})..."

  local existing
  existing=$(kcadm get clients -r DAPS -q "clientId=${client_id}" --fields id 2>/dev/null | grep -o '"id" *: *"[^"]*"' | head -1 | cut -d'"' -f4 || true)

  if [[ -n "$existing" ]]; then
    echo "  Deleting existing client ${client_id} (${existing})..."
    kcadm delete "clients/${existing}" -r DAPS
  fi

  kcadm create clients -r DAPS -s "clientId=${client_id}" \
    -s "enabled=true" \
    -s "clientAuthenticatorType=client-jwt" \
    -s "protocol=openid-connect" \
    -s "publicClient=false" \
    -s "serviceAccountsEnabled=true"

  local new_id
  new_id=$(kcadm get clients -r DAPS -q "clientId=${client_id}" --fields id 2>/dev/null | grep -o '"id" *: *"[^"]*"' | head -1 | cut -d'"' -f4)

  if [[ -z "$new_id" ]]; then
    echo "  ERROR: Failed to find created client." >&2
    return 1
  fi

  local cert_file="$DAPS_DIR/connector-${label}-cert.pem"
  if [[ ! -f "$cert_file" ]]; then
    echo "  ERROR: Certificate not found: $cert_file" >&2
    return 1
  fi

  local cert_pem
  cert_pem=$(grep -v '^\-\-\-' "$cert_file" | tr -d '\n\r')

  kcadm create "clients/${new_id}/certificates/jwt.credential/upload" -r DAPS \
    -s "certificate=${cert_pem}" \
    -s "keystoreFormat=Certificate PEM" 2>/dev/null || \
  kcadm update "clients/${new_id}" -r DAPS \
    -s "attributes.\"jwt.credential.certificate\"=${cert_pem}"

  kcadm create "clients/${new_id}/protocol-mappers/models" -r DAPS \
    -s "name=audience-edc-dsp-api" \
    -s "protocol=openid-connect" \
    -s "protocolMapper=oidc-audience-mapper" \
    -s 'config."included.custom.audience"=edc:dsp-api' \
    -s 'config."access.token.claim"=true' \
    -s 'config."id.token.claim"=false'

  kcadm create "clients/${new_id}/protocol-mappers/models" -r DAPS \
    -s "name=nbf-claim" \
    -s "protocol=openid-connect" \
    -s "protocolMapper=oidc-hardcoded-claim-mapper" \
    -s 'config."claim.name"=nbf' \
    -s 'config."claim.value"=0' \
    -s 'config."jsonType.label"=long' \
    -s 'config."access.token.claim"=true' \
    -s 'config."id.token.claim"=false'

  echo "  -> Registered ${client_id} in DAPS realm."
}

echo "Authenticating to Keycloak..."
get_admin_token

register_connector_daps "$CONNECTOR_A_PARTICIPANT_ID" "a"
register_connector_daps "$CONNECTOR_B_PARTICIPANT_ID" "b"
register_connector_daps "$CONNECTOR_C_PARTICIPANT_ID" "c"

echo ""
echo "All connectors registered in DAPS realm."
