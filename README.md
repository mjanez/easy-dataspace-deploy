# Easy Dataspace Deploy

Deploy a fully-featured Data Space Portal (EDC/DSP compatible) with a single `docker compose up`.

## Overview

This repository provides a ready-to-use Docker Compose stack for deploying the [Data Space Portal](https://github.com/mjanez/dataspace-portal) with:

- Portal frontend + backend + catalog crawler
- Keycloak identity provider (with dev realm and demo users)
- 3 demo EDC connectors with DAPS authentication
- OAuth2 Proxy for secure access
- Caddy reverse proxies
- Optional: Jaeger + Prometheus telemetry

## Prerequisites

- Docker Engine 24+ and Docker Compose v2
- 8 GB RAM minimum
- `openssl` and `curl` (for DAPS certificate generation)

## Quickstart

```bash
# 1. Clone
git clone https://github.com/mjanez/easy-dataspace-deploy.git
cd easy-dataspace-deploy

# 2. Create your environment file
cp .env.example .env

# 3. Generate DAPS certificates
chmod +x connectors/setup-daps-certs.sh crawler/regenerate-daps-certs.sh
./connectors/setup-daps-certs.sh

# 4. Start the stack
docker compose up -d

# 5. Open the portal
# http://portal.localhost:18000
```

### Demo Users

| Email | Password | Role |
|-------|----------|------|
| user1@org1.null | 111 | Authority Admin |
| user3@org2.null | 333 | Participant Admin |
| user7@org4.null | 777 | Service Partner Admin |
| user8@org5.null | 888 | Operator Admin |

## Custom Branding (Flavours)

Customize your portal's look without rebuilding images:

```bash
cat flavours/example/.env.brand >> .env
docker compose up -d
```

| Variable | Purpose |
|----------|---------|
| `FRONTEND_BRAND_LOGO_URL` | Main logo (absolute URL or relative path) |
| `FRONTEND_BRAND_LOGO_SMALL_URL` | Small/collapsed sidebar logo |
| `FRONTEND_BRAND_LOGO_LOGIN_URL` | Login page logo |
| `FRONTEND_BRAND_COPYRIGHT` | Footer copyright text |
| `FRONTEND_PORTAL_DISPLAY_NAME` | Portal title shown in UI |
| `FRONTEND_DATASPACE_SHORT_NAME` | Dataspace short name |

See [flavours/README.md](flavours/README.md) for details.

## Architecture

```
Browser
  |
  v
portal-caddy :18000
  |-- /api, /oauth2 --> oauth2-proxy --> portal-backend (Quarkus)
  |-- /* --> portal-frontend (Angular/nginx)
  |
keycloak :18080 (Identity Provider, DAPS realm)
  |
connector-{a,b,c} :18100-18300 (EDC connectors + management UI)
  |
catalog-crawler :18400 (Dataspace indexer)
  |
portal-db (PostgreSQL, shared by backend + crawler)
```

## Telemetry (Optional)

```bash
./observability/download-otel-agent.sh
docker compose -f docker-compose.yml -f docker-compose.telemetry.yml up -d
# Jaeger UI: http://localhost:16686
# Prometheus: http://localhost:9090
```

## Stopping

```bash
docker compose down        # stop services, keep data
docker compose down -v     # stop services AND delete volumes
```

## Troubleshooting

- **Windows users**: Do NOT use `COMPOSE_FILE` with `:` separator. Use `-f` flags instead.
- **First start is slow**: Keycloak needs ~60-90s to import the realm.
- **DAPS errors**: Ensure you ran `./connectors/setup-daps-certs.sh` before starting.
- **Frontend shows blank page**: Check that `portal-frontend` container started and that `app-configuration.json` is being generated.

## License

Apache License 2.0. See [LICENSE](LICENSE).
