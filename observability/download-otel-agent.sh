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

OTEL_VERSION=$(read_env_var OTEL_JAVAAGENT_VERSION "2.28.1")
AGENT_DIR="$SCRIPT_DIR/agent"
AGENT_JAR="$AGENT_DIR/opentelemetry-javaagent.jar"
VERSION_FILE="$AGENT_DIR/.version"

mkdir -p "$AGENT_DIR"

if [[ -f "$VERSION_FILE" ]] && [[ "$(cat "$VERSION_FILE")" == "$OTEL_VERSION" ]] && [[ -f "$AGENT_JAR" ]]; then
  echo "OpenTelemetry Java agent v${OTEL_VERSION} already downloaded."
  exit 0
fi

DOWNLOAD_URL="https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${OTEL_VERSION}/opentelemetry-javaagent.jar"

echo "Downloading OpenTelemetry Java agent v${OTEL_VERSION}..."
echo "  URL: ${DOWNLOAD_URL}"

curl -fSL -o "$AGENT_JAR" "$DOWNLOAD_URL"

echo "$OTEL_VERSION" > "$VERSION_FILE"

echo "  -> $AGENT_JAR"
echo "Done."
