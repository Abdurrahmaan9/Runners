# Runners

Phase 1 MVP for a local on-demand errand platform. Requesters post tasks. Nearby runners accept them and move the task through a fixed status lifecycle. Live location uses Phoenix Channels.

Payments, wallets, and mobile-money APIs are intentionally out of scope.

## Layout

```text
backend/   Phoenix 1.8 JSON API (Elixir, PostgreSQL/PostGIS, Redis)
```

The Flutter client is the next phase. This kickstart covers authentication, task management, geospatial matching, and the realtime channels the app will use.

## Backend

Requirements:

- Elixir 1.20 / Erlang OTP 29 (already pinned in `.tool-versions`)
- PostgreSQL with the PostGIS extension
- Redis or Valkey on `localhost:6379`

This machine already has PostgreSQL 18 and Valkey. The API connects as `postgres` / `postgres` on `localhost:5432`, and `runners_dev` has been created. PostGIS is the missing piece. Install it, then migrate:

```bash
sudo dnf install postgis
cd backend
mix setup
mix phx.server
```

The API listens on `http://localhost:4000`. `mix setup` migrates `runners_dev` and seeds three users.

If you would rather not install PostGIS on the system database, start the bundled PostGIS container and point the app at port 5433:

```bash
docker compose up -d
cd backend
PGPORT=5433 mix setup
mix phx.server
```

`mix setup` creates `runners_dev`, runs migrations, and seeds three users:

| Phone | Role | Name |
| --- | --- | --- |
| +260971000001 | requester | Amina Banda |
| +260971000002 | runner | Joseph Phiri |
| +260971000003 | admin | Platform Admin |

### Authentication

Registration and login are a mock phone flow. A registered phone number returns a JWT. There is no OTP. Do not deploy this authentication as-is.

```bash
curl -s -X POST http://localhost:4000/api/auth/login \
  -H 'content-type: application/json' \
  -d '{"phone_number":"+260971000001"}'
```

Send the token as `Authorization: Bearer <token>`.

### HTTP API

| Method | Path | Purpose |
| --- | --- | --- |
| POST | `/api/auth/register` | Register a requester or runner |
| POST | `/api/auth/login` | Exchange a phone number for a JWT |
| GET | `/api/auth/me` | Current user |
| PATCH | `/api/runners/me/status` | `{"is_online": true}` |
| POST | `/api/runners/me/location` | `{"lat": -15.3875, "lng": 28.3228}` every 10 seconds |
| GET | `/api/runners/nearby?lat=&lng=&radius_in_meters=` | Online runners inside the radius |
| GET, POST | `/api/tasks` | List or create tasks |
| GET, PATCH, DELETE | `/api/tasks/:id` | Read, edit, or delete a posted task |
| POST | `/api/tasks/:id/accept` | First runner to accept locks the task |
| POST | `/api/tasks/:id/status` | `assigned → runner_arrived → in_progress → completed` |
| POST | `/api/tasks/:id/cancel` | Cancel from any non-terminal status |

Errors use one envelope:

```json
{"error": {"code": "NOT_FOUND", "message": "Task does not exist"}}
```

Validation errors add a `details` object keyed by field.

Runners list their assigned tasks by default. `GET /api/tasks?status=posted` is the open board. Creating a task broadcasts `task_posted` to online runners within 5 km of the pickup point (or the dropoff point when pickup coordinates are absent).

Location pings are written to Redis immediately (`runner:location:<user_id>`, 120 second TTL). PostGIS is updated on the first ping and then every 30 seconds, so nearby search stays current without a database write on every GPS tick.

### Channels

Connect to `ws://localhost:4000/socket/websocket?token=<jwt>`.

- `task_dispatch:<user_id>` — that user only. Events: `task_posted`, `task_updated`.
- `task_tracking:<task_id>` — the requester, the assigned runner, or an admin. While the task is `in_progress`, the runner pushes `location` with `lat` and `lng`. Everyone else on the topic receives `runner_location`.

## Tests

```bash
cd backend
mix test
```
