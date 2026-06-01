# Quickstart

Step-by-step guide to get the Data Space Portal running locally.

## 1. Clone the repository

```bash
git clone https://github.com/mjanez/easy-dataspace-deploy.git
cd easy-dataspace-deploy
```

This gives you the full deployment stack: Docker Compose files, connector configs, Keycloak realm exports, and helper scripts.

## 2. Create your environment file

```bash
cp .env.example .env
```

The `.env.example` file contains sensible defaults for local development. Review it before starting — the most important variables are:

- `PORTAL_PUBLIC_URL` — base URL for the portal (default: `http://portal.localhost:18000`)
- `KEYCLOAK_PUBLIC_URL` — Keycloak URL (default: `http://keycloak.localhost:18080`)
- `POSTGRES_PASSWORD` — database password (change in production)

See [configuration.md](configuration.md) for the full variable reference.

## 3. Generate DAPS certificates

```bash
chmod +x connectors/setup-daps-certs.sh crawler/regenerate-daps-certs.sh
./connectors/setup-daps-certs.sh
```

This script creates self-signed X.509 certificates for each EDC connector and registers them in the DAPS (Dynamic Attribute Provisioning Service) Keycloak realm. Without these certificates, connectors cannot authenticate to the dataspace.

The generated files are placed under `connectors/certs/` and mounted into the connector containers automatically.

## 4. Start the stack

```bash
docker compose up -d
```

This pulls all required images and starts the services. On first run, expect:

- ~2-5 minutes for image pulls (depending on connection speed)
- ~60-90 seconds for Keycloak to import the realm and demo users
- ~30 seconds for the portal backend to run Flyway migrations

Monitor startup progress with:

```bash
docker compose logs -f portal-backend
```

Wait until you see `Quarkus started` in the backend logs before proceeding.

## 5. Open the portal

Navigate to [http://portal.localhost:18000](http://portal.localhost:18000) in your browser.

### Demo Users

Log in with any of the pre-configured demo accounts:

| Email | Password | Role |
|-------|----------|------|
| user1@org1.null | 111 | Authority Admin |
| user3@org2.null | 333 | Participant Admin |
| user7@org4.null | 777 | Service Partner Admin |
| user8@org5.null | 888 | Operator Admin |

## 6. Verify connectors

After login, navigate to **Connectors** in the sidebar. You should see three demo connectors (A, B, C) already registered and online.

If connectors show as offline, check:

```bash
docker compose logs connector-a
docker compose logs connector-b
docker compose logs connector-c
```

## Next steps

- [Configuration reference](configuration.md) — customize ports, URLs, and credentials
- [Custom branding](../flavours/README.md) — apply your organization's logo and colors
- [Telemetry](../observability/) — enable Jaeger tracing and Prometheus metrics
