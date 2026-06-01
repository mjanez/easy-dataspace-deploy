# Configuration Reference

All configuration is managed through the `.env` file. Copy `.env.example` to `.env` and adjust values as needed.

## General

| Variable | Default | Description |
|----------|---------|-------------|
| `COMPOSE_PROJECT_NAME` | `easy-dataspace` | Docker Compose project name prefix for all containers |

## Portal

| Variable | Default | Description |
|----------|---------|-------------|
| `PORTAL_PUBLIC_URL` | `http://portal.localhost:18000` | Public URL where the portal is accessible |
| `PORTAL_BACKEND_IMAGE` | `ghcr.io/mjanez/dataspace-portal/backend` | Backend Docker image |
| `PORTAL_FRONTEND_IMAGE` | `ghcr.io/mjanez/dataspace-portal/frontend` | Frontend Docker image |
| `PORTAL_CADDY_PORT` | `18000` | Host port for the portal reverse proxy |

## Database (PostgreSQL)

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_HOST` | `portal-db` | Database hostname (Docker service name) |
| `POSTGRES_PORT` | `5432` | Database port |
| `POSTGRES_DB` | `portal` | Database name |
| `POSTGRES_USER` | `portal` | Database user |
| `POSTGRES_PASSWORD` | `portal` | Database password (change in production) |

## Keycloak

| Variable | Default | Description |
|----------|---------|-------------|
| `KEYCLOAK_PUBLIC_URL` | `http://keycloak.localhost:18080` | Public URL for Keycloak |
| `KEYCLOAK_PORT` | `18080` | Host port for Keycloak |
| `KEYCLOAK_ADMIN` | `admin` | Keycloak admin username |
| `KEYCLOAK_ADMIN_PASSWORD` | `admin` | Keycloak admin password |
| `KEYCLOAK_REALM` | `portal` | Keycloak realm used by the portal |
| `KEYCLOAK_DAPS_REALM` | `DAPS` | Keycloak realm used for DAPS connector authentication |

## OAuth2 Proxy

| Variable | Default | Description |
|----------|---------|-------------|
| `OAUTH2_PROXY_CLIENT_ID` | `portal-client` | OIDC client ID registered in Keycloak |
| `OAUTH2_PROXY_CLIENT_SECRET` | *(generated)* | OIDC client secret |
| `OAUTH2_PROXY_COOKIE_SECRET` | *(generated)* | Random 32-byte base64 string for cookie encryption |

## Connectors

| Variable | Default | Description |
|----------|---------|-------------|
| `CONNECTOR_A_PUBLIC_URL` | `http://connector-a.localhost:18100` | Public URL for Connector A UI |
| `CONNECTOR_A_INTERNAL_URL` | `http://connector-a:11003` | Internal Docker network URL for Connector A |
| `CONNECTOR_A_PARTICIPANT_ID` | `BPNL000001.conn-a` | Participant ID for Connector A |
| `CONNECTOR_B_PUBLIC_URL` | `http://connector-b.localhost:18200` | Public URL for Connector B UI |
| `CONNECTOR_B_INTERNAL_URL` | `http://connector-b:11003` | Internal Docker network URL for Connector B |
| `CONNECTOR_B_PARTICIPANT_ID` | `BPNL000001.conn-b` | Participant ID for Connector B |
| `CONNECTOR_C_PUBLIC_URL` | `http://connector-c.localhost:18300` | Public URL for Connector C UI |
| `CONNECTOR_C_INTERNAL_URL` | `http://connector-c:11003` | Internal Docker network URL for Connector C |
| `CONNECTOR_C_PARTICIPANT_ID` | `BPNL000002.conn-c` | Participant ID for Connector C |

## Catalog Crawler

| Variable | Default | Description |
|----------|---------|-------------|
| `CRAWLER_PUBLIC_URL` | `http://crawler.localhost:18400` | Public URL for the catalog crawler |
| `CRAWLER_IMAGE` | `ghcr.io/mjanez/dataspace-portal/crawler` | Crawler Docker image |
| `CRAWLER_INTERVAL_SECONDS` | `60` | Interval between catalog crawl runs |

## Branding / Flavours

| Variable | Default | Description |
|----------|---------|-------------|
| `FRONTEND_BRAND_LOGO_URL` | *(portal default)* | Main logo URL |
| `FRONTEND_BRAND_LOGO_SMALL_URL` | *(portal default)* | Collapsed sidebar logo |
| `FRONTEND_BRAND_LOGO_LOGIN_URL` | *(portal default)* | Login page logo |
| `FRONTEND_BRAND_COPYRIGHT` | *(portal default)* | Footer copyright text |
| `FRONTEND_PORTAL_DISPLAY_NAME` | `Data Space Portal` | Portal title in the UI |
| `FRONTEND_DATASPACE_SHORT_NAME` | `Dataspace` | Short name for the dataspace |

See [flavours/README.md](../flavours/README.md) for pre-built brand themes.

## Telemetry (Optional)

| Variable | Default | Description |
|----------|---------|-------------|
| `OTEL_ENABLED` | `false` | Enable OpenTelemetry instrumentation |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `http://jaeger:4317` | OTLP gRPC endpoint for traces |
| `JAEGER_PORT` | `16686` | Host port for Jaeger UI |
| `PROMETHEUS_PORT` | `9090` | Host port for Prometheus UI |

Enable telemetry by starting with the overlay compose file:

```bash
docker compose -f docker-compose.yml -f docker-compose.telemetry.yml up -d
```
