# Tracely – Developer Documentation

Unified API Debugging, Distributed Tracing, and Scenario Automation Platform. Go backend + Flutter frontend + PostgreSQL.

## Table of Contents

- [Intro](#intro)
- [About](#about)
- [Installing and Updating](#installing-and-updating)
  - [Prerequisites](#prerequisites)
  - [Install & Update Script](#install--update-script)
  - [Verify Installation](#verify-installation)
  - [Important Notes](#important-notes)
  - [Manual Install](#manual-install)
- [Configuration](#configuration)
  - [Environment Variables](#environment-variables)
  - [Database](#database)
- [Usage](#usage)
  - [Running the Backend](#running-the-backend)
  - [Running the Frontend](#running-the-frontend)
  - [Default Login](#default-login)
  - [Wireframe Nav (UI Testing)](#wireframe-nav-ui-testing)
- [Running Tests](#running-tests)
- [Project Structure](#project-structure)
- [API Overview](#api-overview)
- [Troubleshooting](#troubleshooting)
  - [Backend](#troubleshooting-backend)
  - [Frontend](#troubleshooting-frontend)
  - [Database](#troubleshooting-database)
- [Uninstalling / Removal](#uninstalling--removal)
- [License & References](#license--references)

---

## Intro

Tracely lets you run a full-stack API observability and automation platform locally or in your environment.

**Example:**

```bash
# Terminal 1: start backend
cd backend && go run main.go
# Server starting on :8081

# Terminal 2: start frontend
cd frontend_1 && flutter run -d chrome
# Open app → AUTH → login admin@tracely.com / admin123 → use WORKSPACES, TRACING, etc.
```

Simple as that.

---

## About

Tracely is a **version-agnostic** development platform:

- **Backend:** Go (Gin), PostgreSQL (GORM), JWT auth, trace propagation (HTTP/gRPC/GraphQL), workspace-scoped APIs.
- **Frontend:** Flutter (Dart), cross-platform (web, iOS, Android, desktop), Provider state, single `ApiService` base URL.
- **Features:** Auth, workspaces, collections, request execution, distributed traces, waterfall/critical path, monitoring topology, replays, mocks, workflows, environments, governance, settings.

It runs on **macOS, Linux, and Windows (WSL)**. For production, use a proper `JWT_SECRET` and database configuration.

---

## Installing and Updating

### Prerequisites

- **Go 1.22+** – [Download](https://go.dev/dl/)
- **PostgreSQL 14+** – [Download](https://www.postgresql.org/download/)
- **Flutter** (for frontend) – [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Git** – for cloning and version control

Optional: **Make** (for `make run`, `make test`), **Docker** (for PostgreSQL or full stack).

### Install & Update Script

**1. Clone the repository**

```bash
git clone <repository-url>
cd Unified-API-debugging-Distributed-Tracing-and-scenario-automation-platform
```

**2. Backend setup**

```bash
cd backend
cp .env.example .env
# Edit .env: set DATABASE_URL and JWT_SECRET (see Configuration)
go mod download
createdb tracely_dev   # or use Docker; see Database
go run main.go
```

**3. Frontend setup**

```bash
cd frontend_1
flutter pub get
flutter run -d chrome  # or -d macos, -d windows, or a device
```

**4. Update from repo**

```bash
git pull
cd backend && go mod tidy && go build ./...
cd frontend_1 && flutter pub get
```

### Verify Installation

- **Backend:** `curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/api/v1/workspaces` → should return `401` (unauthorized).
- **Frontend:** Open app → tap **☰ (Wireframe NAV)** → choose **AUTH** → login with `admin@tracely.com` / `admin123` → choose **HOME** → tap green **Check Backend** FAB → should see “✅ Backend is reachable!”.

To confirm Go and Flutter:

```bash
go version    # go1.22 or higher
flutter --version
psql --version  # or docker run postgres:14 --version
```

### Important Notes

- Backend **default port is 8081**. The Flutter app uses `http://localhost:8081/api/v1`; change `PORT` in `.env` and `baseUrl` in `frontend_1/lib/services/api_service.dart` if you use another port.
- On **first run**, migrations create tables and seed a default user **only if no users exist** (see [Default Login](#default-login)).
- **CORS:** Backend allows `CORS_ORIGINS` from `.env`; add your frontend origin (e.g. `http://localhost:XXXX`) if you get CORS errors.
- **Homebrew:** We do not recommend installing Go or PostgreSQL via Homebrew for this project if you see path or version conflicts; use official installers or Docker.

### Manual Install

**Backend (no Make):**

```bash
cd backend
cp .env.example .env
# Edit .env
go mod download
createdb tracely_dev
go run main.go
```

**Frontend (no IDE):**

```bash
cd frontend_1
flutter pub get
flutter run -d chrome
```

**Database (Docker):**

```bash
docker run -d --name tracely-pg \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=tracely_dev \
  -p 5432:5432 \
  postgres:14
```

Then set `DATABASE_URL=postgres://postgres:postgres@localhost:5432/tracely_dev?sslmode=disable` in `backend/.env`.

---

## Configuration

### Environment Variables

Backend reads from `backend/.env` (or environment). Key variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `ENVIRONMENT` | `development` or `production` | `development` |
| `PORT` | HTTP server port | `8081` |
| `DATABASE_URL` | PostgreSQL connection string | `postgres://postgres:postgres@localhost:5432/tracely_dev?sslmode=disable` |
| `JWT_SECRET` | Secret for signing JWTs; **must** be set in production | (see `.env.example`) |
| `JWT_EXPIRATION` | Access token TTL | `1h` |
| `REFRESH_EXPIRATION` | Refresh token TTL | `720h` |
| `CORS_ORIGINS` | Comma-separated allowed origins | `http://localhost,...` |
| `LOG_LEVEL` | Log verbosity | `info` |
| `TRACE_STORAGE_DIR` | Optional trace storage path | `./traces` |

Generate a secure `JWT_SECRET` for production:

```bash
openssl rand -base64 32
```

### Database

- **Name:** `tracely_dev` (or whatever `DATABASE_URL` uses).
- **Migrations:** Run automatically on backend startup (`database.RunMigrations`).
- **Seed:** If no users exist, a default user is created (see [Default Login](#default-login)).
- **Reset (destructive):** `dropdb tracely_dev && createdb tracely_dev`, then restart backend.

---

## Usage

### Running the Backend

```bash
cd backend
go run main.go
```

Or with Make: `make run`. Server listens on `http://localhost:8081` (or your `PORT`).

### Running the Frontend

```bash
cd frontend_1
flutter run -d chrome   # web
flutter run -d macos    # macOS desktop
flutter run             # default device
```

For **Android emulator**, the app uses `http://10.0.2.2:8081` (see comments in `api_service.dart`). For a **physical device**, set `baseUrl` to your machine’s IP (e.g. `http://192.168.1.10:8081/api/v1`).

### Default Login

If the database had no users when the backend first ran, a default user is seeded:

- **Email:** `admin@tracely.com`
- **Password:** `admin123`

Use these in the **AUTH** screen to log in. For production, remove or disable the seed and use normal registration.

### Wireframe Nav (UI Testing)

Use the **bottom bar** in the app: tap **☰** next to “WIREFRAME NAV:” and select a section (LANDING, AUTH, HOME, WORKSPACES, STUDIO, COLLECTIONS, MONITORING, REPLAY, TRACING, GOVERNANCE, SETTINGS). See [WIREFRAME_NAV_TESTING_GUIDE.md](WIREFRAME_NAV_TESTING_GUIDE.md) for step-by-step testing.

---

## Running Tests

**All tests (backend + frontend):**

```bash
./run_all_tests.sh
```

**With API smoke test (backend must be running on 8081):**

```bash
./run_all_tests.sh --api
```

**Backend only:**

```bash
cd backend
go test ./...
```

**Frontend only:**

```bash
cd frontend_1
flutter test
```

**Verify installation (one-liner):**

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/api/v1/workspaces
# 401 = server up
```

---

## Project Structure

```
.
├── backend/                 # Go API server
│   ├── main.go              # Entry point, router, middleware
│   ├── config/              # Config load (env)
│   ├── database/            # DB init, migrations, seed
│   ├── handlers/            # HTTP handlers (auth, workspaces, traces, …)
│   ├── middlewares/        # Auth, trace ID, logger, error, gRPC, GraphQL
│   ├── models/              # GORM models
│   ├── services/            # Business logic
│   ├── integrations/        # Postman, CI/CD, Prometheus, etc.
│   └── .env.example
├── frontend_1/              # Flutter app
│   ├── lib/
│   │   ├── main.dart        # App entry, wireframe nav, screens
│   │   ├── providers/       # Auth, workspace, trace, replay, …
│   │   ├── screens/        # Landing, auth, home, workspaces, studio, …
│   │   ├── services/       # api_service.dart (baseUrl, HTTP calls)
│   │   └── widgets/
│   ├── test/
│   └── pubspec.yaml
├── openapi.yaml             # API spec
├── run_all_tests.sh         # Backend + Flutter + optional API smoke
├── HOW_TO_CHECK.md          # How to check backend & frontend
├── WIREFRAME_NAV_TESTING_GUIDE.md
├── PHASE1_IMPLEMENTATION_AUDIT.md
└── DEV_DOCS.md              # This file
```

---

## API Overview

- **Base URL:** `http://localhost:8081/api/v1` (or your `PORT` and host).
- **Auth:** `POST /auth/register`, `POST /auth/login`; use `Authorization: Bearer <access_token>` for protected routes.
- **Key groups:** `/workspaces`, `/workspaces/:id/collections`, `/workspaces/:id/traces`, `/workspaces/:id/monitoring`, `/workspaces/:id/replays`, `/workspaces/:id/mocks`, `/workspaces/:id/tracing/configs`, `/users/settings`, etc.
- **Spec:** See `openapi.yaml` and `backend_api_documentation.md` for full contracts.

---

## Troubleshooting

### Troubleshooting Backend

**`nvm: command not found`**  
This project does not use nvm. Use Go and Flutter as in [Prerequisites](#prerequisites).

**`connection refused` to backend**  
- Ensure backend is running (`go run main.go` in `backend/`).
- Confirm port 8081 (or your `PORT`) is not in use by another process.
- If using a device or emulator, use the correct host (e.g. `10.0.2.2` for Android emulator).

**`Failed to connect to database`**  
- PostgreSQL is running.
- `DATABASE_URL` in `backend/.env` is correct; database (e.g. `tracely_dev`) exists.
- On Linux/macOS: `psql -U postgres -c "SELECT 1"` and `createdb tracely_dev` if needed.

**`JWT_SECRET must be set in production`**  
Set `JWT_SECRET` in `backend/.env` (or env) when `ENVIRONMENT=production`. Use a long random value (e.g. `openssl rand -base64 32`).

### Troubleshooting Frontend

**`ProviderNotFoundException` (e.g. AuthProvider)**  
The app must be run with the full widget tree (e.g. `flutter run`), not a single screen in tests without providers. See `frontend_1/test/widget_test.dart` for a minimal test setup.

**CORS errors in browser**  
Add your frontend origin to `CORS_ORIGINS` in `backend/.env` (e.g. `http://localhost:12345` for web).

**“Check Backend” shows Unauthorized**  
Log in again (AUTH). The app stores `access_token` as `user['token']`; if you changed backend to only return `token`, ensure the provider maps it (see `auth_provider.dart`).

### Troubleshooting Database

**Migrations fail or schema out of date**  
- Ensure no other process is holding locks.
- For a clean slate: `dropdb tracely_dev && createdb tracely_dev`, then restart backend to re-run migrations and seed.

**Seed user not created**  
Seed runs only when the `users` table is empty. If you already had users, register a new one or reset the DB and restart.

---

## Uninstalling / Removal

**Backend:** Remove the `backend/` directory. No global Go install is required if you only use `go run`/`go build` from the project.

**Frontend:** Remove the `frontend_1/` directory. Flutter SDK can remain for other projects.

**Database:**  
```bash
dropdb tracely_dev
# or
docker stop tracely-pg && docker rm tracely-pg
```

**Full cleanup:** Delete the project directory and, if desired, uninstall Go, Flutter, and PostgreSQL per their official docs.

---

## License & References

- **Project:** Unified API Debugging, Distributed Tracing, and Scenario Automation Platform (Tracely).
- **Root README:** [README.md](README.md) (SRS and requirements).
- **Backend README:** [backend/README.md](backend/README.md).
- **How to check backend & frontend:** [HOW_TO_CHECK.md](HOW_TO_CHECK.md).
- **Wireframe nav testing:** [WIREFRAME_NAV_TESTING_GUIDE.md](WIREFRAME_NAV_TESTING_GUIDE.md).
- **nvm (Node Version Manager):** [GitHub - nvm-sh/nvm](https://github.com/nvm-sh/nvm) – format reference for this doc; this project does not use Node or nvm.
