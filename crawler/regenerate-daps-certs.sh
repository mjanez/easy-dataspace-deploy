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

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Generate DAPS certificate for the catalog crawler.

Options:
  -i, --participant-id ID   Participant ID (default: from .env or BPNL000001.CRAWLER)
  -d, --days DAYS           Certificate validity in days (default: 365)
  -r, --recreate            Reset crawler DAPS registration after regenerating
  -y, --yes                 Skip confirmation prompts
  -h, --help                Show this help message
EOF
  exit 0
}

PARTICIPANT_ID=""
DAYS=365
RECREATE=false
YES=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--participant-id) PARTICIPANT_ID="$2"; shift 2 ;;
    -d|--days) DAYS="$2"; shift 2 ;;
    -r|--recreate) RECREATE=true; shift ;;
    -y|--yes) YES=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done

if [[ -z "$PARTICIPANT_ID" ]]; then
  PARTICIPANT_ID=$(read_env_var CRAWLER_PARTICIPANT_ID "BPNL000001.CRAWLER")
fi

PORTAL_DEPLOYMENT_ENVIRONMENT=$(read_env_var PORTAL_DEPLOYMENT_ENVIRONMENT "test")

DAPS_DIR="$SCRIPT_DIR"

if [[ "${MSYSTEM:-}" =~ MINGW|MSYS ]] || [[ "$(uname -s)" =~ MINGW|MSYS ]]; then
  export MSYS_NO_PATHCONV=1
fi

echo "Generating DAPS certificate for crawler (${PARTICIPANT_ID})..."
echo "  Validity: ${DAYS} days"
echo "  Environment: ${PORTAL_DEPLOYMENT_ENVIRONMENT}"

openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout "$DAPS_DIR/daps-priv.pem" \
  -out "$DAPS_DIR/daps-cert.pem" \
  -days "$DAYS" \
  -subj "/CN=${PARTICIPANT_ID}" 2>/dev/null

cert_b64=$(base64 -w0 < "$DAPS_DIR/daps-cert.pem" 2>/dev/null || base64 < "$DAPS_DIR/daps-cert.pem" | tr -d '\n')
priv_b64=$(base64 -w0 < "$DAPS_DIR/daps-priv.pem" 2>/dev/null || base64 < "$DAPS_DIR/daps-priv.pem" | tr -d '\n')

cat > "$DAPS_DIR/daps-vault.env" <<EOF
sovity.vault.in-memory.init.daps-cert=${cert_b64}
sovity.vault.in-memory.init.daps-priv=${priv_b64}
EOF

cert_oneline=$(grep -v '^\-\-\-' "$DAPS_DIR/daps-cert.pem" | tr -d '\n\r')

cat > "$DAPS_DIR/portal-central-component.properties" <<EOF
portal.deployment.environment=${PORTAL_DEPLOYMENT_ENVIRONMENT}
portal.catalog-crawler.participant-id=${PARTICIPANT_ID}
portal.catalog-crawler.daps-certificate=${cert_oneline}
EOF

echo "  -> $DAPS_DIR/daps-cert.pem"
echo "  -> $DAPS_DIR/daps-priv.pem"
echo "  -> $DAPS_DIR/daps-vault.env"
echo "  -> $DAPS_DIR/portal-central-component.properties"

if [[ "$RECREATE" == "true" ]]; then
  RESET_SCRIPT="$DEPLOY_DIR/scripts/reset-crawler-daps-registration.sh"
  if [[ -x "$RESET_SCRIPT" ]]; then
    if [[ "$YES" != "true" ]]; then
      read -rp "Reset crawler DAPS registration? [y/N] " confirm
      if [[ "$confirm" != [yY] ]]; then
        echo "Skipped reset."
        exit 0
      fi
    fi
    echo "Resetting crawler DAPS registration..."
    "$RESET_SCRIPT"
  else
    echo "WARNING: Reset script not found or not executable: $RESET_SCRIPT" >&2
  fi
fi

echo ""
echo "Done."
