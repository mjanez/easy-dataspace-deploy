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

compose() {
  docker compose --project-directory "$DEPLOY_DIR" "$@"
}

KEYCLOAK_ADMIN_USER=$(read_env_var KEYCLOAK_ADMIN_USER admin)
KEYCLOAK_ADMIN_PASSWORD=$(read_env_var KEYCLOAK_ADMIN_PASSWORD admin)
KEYCLOAK_PORT=$(read_env_var KEYCLOAK_PORT 18080)

CONNECTOR_A_PARTICIPANT_ID=$(read_env_var CONNECTOR_A_PARTICIPANT_ID "BPNL000001.CONN001")
CONNECTOR_B_PARTICIPANT_ID=$(read_env_var CONNECTOR_B_PARTICIPANT_ID "BPNL000001.CONN002")
CONNECTOR_C_PARTICIPANT_ID=$(read_env_var CONNECTOR_C_PARTICIPANT_ID "BPNL000001.CONN003")

DAPS_DIR="$SCRIPT_DIR/daps"
mkdir -p "$DAPS_DIR"

OPENSSL_CMD="openssl"
if [[ "${MSYSTEM:-}" =~ MINGW|MSYS ]] || [[ "$(uname -s)" =~ MINGW|MSYS ]]; then
  export MSYS_NO_PATHCONV=1
fi

generate_cert() {
  local participant_id="$1"
  local label="$2"

  echo "Generating DAPS certificate for connector-${label} (${participant_id})..."

  $OPENSSL_CMD req -x509 -newkey rsa:2048 -nodes \
    -keyout "$DAPS_DIR/connector-${label}-priv.pem" \
    -out "$DAPS_DIR/connector-${label}-cert.pem" \
    -days 365 \
    -subj "/CN=${participant_id}" 2>/dev/null

  local cert_b64 priv_b64
  cert_b64=$(base64 -w0 < "$DAPS_DIR/connector-${label}-cert.pem" 2>/dev/null || base64 < "$DAPS_DIR/connector-${label}-cert.pem" | tr -d '\n')
  priv_b64=$(base64 -w0 < "$DAPS_DIR/connector-${label}-priv.pem" 2>/dev/null || base64 < "$DAPS_DIR/connector-${label}-priv.pem" | tr -d '\n')

  cat > "$DAPS_DIR/connector-${label}-vault.env" <<EOF
sovity.vault.in-memory.init.daps-cert=${cert_b64}
sovity.vault.in-memory.init.daps-priv=${priv_b64}
EOF

  echo "  -> $DAPS_DIR/connector-${label}-cert.pem"
  echo "  -> $DAPS_DIR/connector-${label}-priv.pem"
  echo "  -> $DAPS_DIR/connector-${label}-vault.env"
}

generate_cert "$CONNECTOR_A_PARTICIPANT_ID" "a"
generate_cert "$CONNECTOR_B_PARTICIPANT_ID" "b"
generate_cert "$CONNECTOR_C_PARTICIPANT_ID" "c"

if [[ -x "$SCRIPT_DIR/register-daps-keycloak.sh" ]]; then
  echo ""
  echo "Registering connectors in Keycloak DAPS realm..."
  "$SCRIPT_DIR/register-daps-keycloak.sh"
fi

if [[ -x "$DEPLOY_DIR/crawler/regenerate-daps-certs.sh" ]]; then
  echo ""
  echo "Regenerating crawler DAPS certificate..."
  "$DEPLOY_DIR/crawler/regenerate-daps-certs.sh"
fi

echo ""
echo "Done. To apply the new certificates, recreate the connectors:"
echo "  docker compose down connector-a-connector connector-b-connector connector-c-connector"
echo "  docker compose up -d connector-a-connector connector-b-connector connector-c-connector"
