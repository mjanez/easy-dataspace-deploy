# Flavours

A flavour is a set of environment variable overrides that customize the portal's branding.

## How to apply a flavour

```bash
cp ../.env.example ../.env
cat example/.env.brand >> ../.env
docker compose up -d
```

## Available variables

| Variable | Purpose |
|----------|---------|
| `FRONTEND_BRAND_LOGO_URL` | Main logo (absolute URL or relative) |
| `FRONTEND_BRAND_LOGO_SMALL_URL` | Small/collapsed sidebar logo |
| `FRONTEND_BRAND_LOGO_LOGIN_URL` | Login page logo |
| `FRONTEND_BRAND_COPYRIGHT` | Footer copyright text |
| `FRONTEND_PORTAL_DISPLAY_NAME` | Portal title in UI |
| `FRONTEND_DATASPACE_SHORT_NAME` | Dataspace short name |

## Creating your own flavour

1. Create a directory: `flavours/my-org/`
2. Add `.env.brand` with your overrides
3. Optionally host your logo at a public URL
