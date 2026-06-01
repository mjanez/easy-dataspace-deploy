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

CRAWLER_PARTICIPANT_ID=$(read_env_var CRAWLER_PARTICIPANT_ID "BPNL000001.CRAWLER")

compose() {
  docker compose --project-directory "$DEPLOY_DIR" "$@"
}

keycloak_container() {
  docker ps --filter "name=keycloak" --filter "status=running" --format "{{.Names}}" | head -1
}

echo "Resetting crawler DAPS registration..."

echo "  Removing crawler from portal DB component table..."
compose exec portal-db psql -U portal -d portal -c \
  "DELETE FROM component WHERE participant_id = '${CRAWLER_PARTICIPANT_ID}';" 2>/dev/null || true

echo "  Removing crawler DAPS client from Keycloak..."
KC_CONTAINER=$(keycloak_container)
if [[ -n "$KC_CONTAINER" ]]; then
  docker exec "$KC_CONTAINER" /opt/keycloak/bin/kcadm.sh config credentials \
    --server http://localhost:8080 --realm master --user admin --password admin 2>/dev/null || true

  CLIENT_ID=$(docker exec "$KC_CONTAINER" /opt/keycloak/bin/kcadm.sh get clients -r DAPS \
    -q "clientId=${CRAWLER_PARTICIPANT_ID}" --fields id 2>/dev/null | grep -o '"id" *: *"[^"]*"' | head -1 | cut -d'"' -f4 || true)

  if [[ -n "$CLIENT_ID" ]]; then
    docker exec "$KC_CONTAINER" /opt/keycloak/bin/kcadm.sh delete "clients/${CLIENT_ID}" -r DAPS
    echo "  -> Deleted DAPS client: ${CRAWLER_PARTICIPANT_ID}"
  fi
fi

echo "  Re-running portal seed..."
compose up -d portal-seed --force-recreate 2>/dev/null || true
sleep 5

echo "  Recreating portal-backend and catalog-crawler..."
compose up -d portal-backend catalog-crawler --force-recreate

echo ""
echo "Crawler DAPS registration reset complete."
