#!/usr/bin/env bash
set -euo pipefail

KC_SERVER="${KC_SERVER:-http://keycloak.localhost:18080}"
PORTAL_URL="${PORTAL_URL:-http://portal.localhost:18000}"
DAPS_CLIENT_SECRET="${DAPS_CLIENT_SECRET:-local-daps-secret}"
AUTHORITY_REALM="${AUTHORITY_REALM:-authority-portal}"
OAUTH2_PROXY_CLIENT_ID="${OAUTH2_PROXY_CLIENT_ID:-oauth2-proxy}"
PORTAL_CLIENT_ID="${PORTAL_CLIENT_ID:-authority-portal-client}"

KC_INTERNAL="http://localhost:8080"

kcadm() {
  /opt/keycloak/bin/kcadm.sh "$@"
}

echo "Waiting for Keycloak to become ready..."
for i in $(seq 1 120); do
  if kcadm config credentials --server "$KC_INTERNAL" --realm master --user admin --password admin 2>/dev/null; then
    echo "Keycloak is ready."
    break
  fi
  if [[ "$i" -eq 120 ]]; then
    echo "ERROR: Keycloak did not become ready in time." >&2
    exit 1
  fi
  sleep 2
done

echo "Setting login theme to portal-theme..."
kcadm update "realms/${AUTHORITY_REALM}" -s "loginTheme=portal-theme"
kcadm update "realms/${AUTHORITY_REALM}" -s "emailTheme=portal-theme"

echo "Patching oauth2-proxy redirect URIs..."
OAUTH2_ID=$(kcadm get clients -r "$AUTHORITY_REALM" -q "clientId=${OAUTH2_PROXY_CLIENT_ID}" --fields id | grep -o '"id" *: *"[^"]*"' | head -1 | cut -d'"' -f4)
if [[ -n "$OAUTH2_ID" ]]; then
  kcadm update "clients/${OAUTH2_ID}" -r "$AUTHORITY_REALM" \
    -s "redirectUris=[\"${PORTAL_URL}/*\"]" \
    -s "webOrigins=[\"${PORTAL_URL}\"]"
fi

echo "Patching authority-portal-client redirect URIs..."
PORTAL_CID=$(kcadm get clients -r "$AUTHORITY_REALM" -q "clientId=${PORTAL_CLIENT_ID}" --fields id | grep -o '"id" *: *"[^"]*"' | head -1 | cut -d'"' -f4)
if [[ -n "$PORTAL_CID" ]]; then
  kcadm update "clients/${PORTAL_CID}" -r "$AUTHORITY_REALM" \
    -s "redirectUris=[\"${PORTAL_URL}/*\"]" \
    -s "webOrigins=[\"${PORTAL_URL}\"]"
fi

echo "Setting demo user passwords..."
DEMO_USERS=("user1" "user2" "user3" "user4" "user5" "user6" "user7" "user8")
DEMO_PASSWORDS=("111" "222" "333" "444" "555" "666" "777" "888")

for idx in "${!DEMO_USERS[@]}"; do
  user="${DEMO_USERS[$idx]}"
  pass="${DEMO_PASSWORDS[$idx]}"
  uid=$(kcadm get users -r "$AUTHORITY_REALM" -q "username=${user}" --fields id | grep -o '"id" *: *"[^"]*"' | head -1 | cut -d'"' -f4 || true)
  if [[ -n "$uid" ]]; then
    kcadm set-password -r "$AUTHORITY_REALM" --userid "$uid" --new-password "$pass" 2>/dev/null || true
  fi
done

echo "Configuring DAPS realm..."
DAPS_REALM_EXISTS=$(kcadm get realms --fields realm | grep -c '"DAPS"' || true)
if [[ "$DAPS_REALM_EXISTS" -eq 0 ]]; then
  echo "  Creating DAPS realm..."
  kcadm create realms -s realm=DAPS -s enabled=true
fi

echo "Configuring authority-portal client in DAPS realm..."
AP_DAPS_ID=$(kcadm get clients -r DAPS -q "clientId=authority-portal" --fields id | grep -o '"id" *: *"[^"]*"' | head -1 | cut -d'"' -f4 || true)

if [[ -z "$AP_DAPS_ID" ]]; then
  kcadm create clients -r DAPS \
    -s "clientId=authority-portal" \
    -s "enabled=true" \
    -s "secret=${DAPS_CLIENT_SECRET}" \
    -s "clientAuthenticatorType=client-secret" \
    -s "protocol=openid-connect" \
    -s "publicClient=false" \
    -s "serviceAccountsEnabled=true"
  AP_DAPS_ID=$(kcadm get clients -r DAPS -q "clientId=authority-portal" --fields id | grep -o '"id" *: *"[^"]*"' | head -1 | cut -d'"' -f4)
else
  kcadm update "clients/${AP_DAPS_ID}" -r DAPS \
    -s "secret=${DAPS_CLIENT_SECRET}" \
    -s "serviceAccountsEnabled=true"
fi

SA_ID=$(kcadm get "clients/${AP_DAPS_ID}/service-account-user" -r DAPS --fields id | grep -o '"id" *: *"[^"]*"' | head -1 | cut -d'"' -f4 || true)
if [[ -n "$SA_ID" ]]; then
  RM_CLIENT_ID=$(kcadm get clients -r DAPS -q "clientId=realm-management" --fields id | grep -o '"id" *: *"[^"]*"' | head -1 | cut -d'"' -f4 || true)
  if [[ -n "$RM_CLIENT_ID" ]]; then
    for role in manage-clients view-clients query-clients; do
      ROLE_ID=$(kcadm get "clients/${RM_CLIENT_ID}/roles/${role}" -r DAPS --fields id 2>/dev/null | grep -o '"id" *: *"[^"]*"' | head -1 | cut -d'"' -f4 || true)
      if [[ -n "$ROLE_ID" ]]; then
        kcadm add-roles -r DAPS --uusername "service-account-authority-portal" \
          --cclientid realm-management --rolenames "$role" 2>/dev/null || true
      fi
    done
  fi
fi

echo ""
echo "Keycloak initialization complete."
