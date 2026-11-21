# Storybook School

Storybook School is a primary-school reading and assessment app. It keeps the existing plain Node.js HTTP server, static browser frontend, SQLite/PostgreSQL data layer, Vercel static hosting, and Render API arrangement.

## Requirements and local setup

- Node.js 22.5 or newer (Node 24 is recommended)
- npm (or pnpm with the checked-in lockfile)
- PostgreSQL/Supabase for shared production use, or built-in `node:sqlite` for local use

```sh
npm install
cp .env.example .env
npm start
```

Open `http://localhost:3000`. With `DATABASE_URL` blank, the server creates `storybook.db`, installs SQLite migrations in order, and seeds an administrator account (`admin` / `Admin@12345`). Change that bootstrap password immediately; it is public, known starter credentials.

Run automated checks with `npm test`; build the static Vercel frontend with `npm run build`.

## Environment variables

| Variable | Required | Purpose |
|---|---|---|
| `PORT` | No | HTTP listen port; defaults to 3000. |
| `DATABASE_URL` | Production | PostgreSQL connection string. Leave empty for SQLite. |
| `PGSSL` | No | Set to `1` to require TLS for PostgreSQL; common hosted database URLs enable SSL automatically. |
| `DB` | No | Alternate SQLite file path (only when `DATABASE_URL` is unset). |
| `HTTPS` | Production | Set to `1` behind Render's HTTPS proxy for secure cookies and HSTS. |
| `CORS_ORIGINS` | Production | Comma-separated exact frontend origins, including scheme, without trailing slash. |
| `ANTHROPIC_API_KEY` | No | Server-only key enabling AI story/question tools. Never expose to the frontend. |
| `ANTHROPIC_MODEL` | No | Server-side model override for AI tools. |
| `AI_DAILY_LIMIT` | No | Maximum AI calls per teacher each day; defaults to 30. |
| `SUPABASE_URL` | Optional, in a set | Supabase project URL for private uploads. |
| `SUPABASE_SERVICE_ROLE_KEY` | Optional, in a set | Server-only Supabase service-role key. Never expose to the browser. |
| `STORAGE_BUCKET` | Optional, in a set | Private Supabase Storage bucket for source uploads. |

`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, and `STORAGE_BUCKET` must be configured together. Optional feature variables are not needed for a standard local run. Configure production secrets in Render's environment settings, not in repository files or `public/`.

## PostgreSQL / Supabase database setup

1. Create a PostgreSQL database and an application connection string (Supabase session pooler is suitable).
2. Back up existing data before applying schema changes.
3. For a new database only, run `schema.postgres.sql` once to create the original base schema.
4. Run `migrations/storybook-upgrade-001.postgres.sql`, then `002`, `003`, and `004` in numeric order. For the SQLite equivalent use the matching `.sqlite.sql` files. These upgrade scripts are idempotent; migration 001 creates the migration ledger and the server runner records successful upgrades in `schema_migrations`.
5. Set `DATABASE_URL` (and `PGSSL=1` if required) on the API server and start it. The startup migration runner applies any unrecorded upgrade scripts in numeric order. Do not execute schema upgrades out of order.
6. Verify `GET /api/health` returns `{"ok":true,...}`.

The server uses PostgreSQL when `DATABASE_URL` is set, otherwise SQLite. Existing table timestamps are Unix milliseconds.

## Existing deployment (Vercel + Render)

### Render API

- Deploy the repository's Node server; set `NODE_VERSION` to 22.5 or later.
- Configure `DATABASE_URL`, `HTTPS=1`, and `CORS_ORIGINS` for the exact Vercel/custom domains.
- Set the Render health-check path to **`/api/health`**. The endpoint executes a database query and responds successfully only when the database is reachable.
- Put optional AI and storage secrets on Render only.

### Vercel frontend

- Keep the existing `vercel.json` rewrite to the Render API.
- Build command: `npm run build`; output directory: `dist`.
- If the API host or frontend domain changes, update the rewrite and CORS origin configuration together.

On a Render cold start, the browser displays a friendly waking-up status and retries transient network/502/503/504 responses. Other errors are still reported normally.

## Backup and security

An administrator can download JSON or CSV from the dashboard. The backup omits password hashes and session tokens; nevertheless, the export contains sensitive school data and should be stored securely. The backup endpoint is restricted server-side to the `admin` role.

Read `docs/SECURITY_REVIEW.md`, `docs/TESTING.md`, and `docs/UPGRADE_SCOPE.md` before production use. Change the seeded administrator password, use a private repository, configure the private upload bucket's size/MIME limits, and test database migrations against staging before production.
