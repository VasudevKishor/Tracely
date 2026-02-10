# How to Check the Backend & Frontend Integration

Use these steps to verify the backend runs correctly and the frontend can talk to it.

---

## 1. Prerequisites

- **Go 1.22+** – [golang.org/dl](https://go.dev/dl/)
- **PostgreSQL 14+** – running locally or in Docker
- **Flutter** (for frontend) – [flutter.dev](https://flutter.dev)

---

## 2. Start the backend

### 2.1 Database

Create the database (if it doesn’t exist):

```bash
# PostgreSQL CLI
createdb tracely_dev
```

Or with Docker:

```bash
docker run -d --name tracely-pg -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=tracely_dev -p 5432:5432 postgres:14
```

### 2.2 Environment

From the project root:

```bash
cd backend
cp .env.example .env
```

Edit `.env` and set at least:

- `DATABASE_URL` – e.g. `postgres://postgres:postgres@localhost:5432/tracely_dev?sslmode=disable`
- `JWT_SECRET` – any long random string (e.g. `openssl rand -base64 32`)

Default `PORT` is **8081** (frontend expects this).

### 2.3 Run the server

```bash
cd backend
go mod download
go run main.go
```

You should see something like:

```text
Database connection established
Database migrations completed successfully
Server starting on :8081
```

If you see that, the backend is up.

---

## 3. Check the backend with curl

Use **port 8081** (or whatever you set in `.env`). Base URL: `http://localhost:8081/api/v1`.

### 3.1 Register & login

```bash
# Register
curl -s -X POST http://localhost:8081/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","name":"Test User"}'

# Login (response includes access_token and refresh_token)
curl -s -X POST http://localhost:8081/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

Copy the `access_token` from the login response and set:

```bash
export TOKEN="<paste_access_token_here>"
```

### 3.2 Protected endpoints

```bash
# List workspaces (should return {"workspaces": [...]})
curl -s -X GET http://localhost:8081/api/v1/workspaces \
  -H "Authorization: Bearer $TOKEN"

# Create a workspace
curl -s -X POST http://localhost:8081/api/v1/workspaces \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"My Workspace","description":"Test"}'
```

If these return JSON (and workspaces returns an array), auth and routing are working.

### 3.3 Trace headers (middleware)

```bash
curl -s -i -X GET http://localhost:8081/api/v1/workspaces \
  -H "Authorization: Bearer $TOKEN"
```

Check response headers for:

- `X-Trace-ID`
- `X-Span-ID`

If present, trace middleware is active.

---

## 4. Run backend tests (optional)

```bash
cd backend
go test ./...
```

Fix any failing tests; at least `middlewares/trace_test.go` should pass.

---

## 5. Check frontend integration

### 5.1 Base URL

The Flutter app uses:

- **Web / desktop:** `http://localhost:8081/api/v1`
- **Android emulator:** `http://10.0.2.2:8081/api/v1`
- **Real device:** `http://<your-machine-IP>:8081/api/v1`

So the backend must be running on **8081** (or change `baseUrl` in `frontend_1/lib/services/api_service.dart`).

### 5.2 Run the frontend

```bash
cd frontend_1
flutter pub get
flutter run -d chrome
# or: flutter run -d macos / flutter run
```

### 5.3 Quick UI checks

1. **Login / Register** – use the same email/password you used in curl. You should get in without “connection refused” or 404.
2. **Workspaces** – create a workspace and see it in the list (calls `GET /api/v1/workspaces`).
3. **Collections** – create a collection in a workspace (`POST .../workspaces/:id/collections`).
4. **Traces** – open the trace/monitoring screen; it should load without errors (may be empty).
5. **Settings** – open user settings; should load (`GET /api/v1/users/settings`).

If these screens load and don’t show network errors, backend–frontend integration is working for those flows.

### 5.4 Browser devtools

- Open DevTools (F12) → **Network**.
- Trigger actions (login, load workspaces, open traces, etc.).
- Check that requests go to `http://localhost:8081/api/v1/...` and return 200 (or expected codes). Any 401/403/404/500 will show there.

---

## 6. Common issues

| Symptom | What to check |
|--------|----------------|
| `connection refused` to backend | Backend not running, or wrong port (use 8081). |
| 401 on every request | Token not sent or expired; login again and ensure `Authorization: Bearer <token>` is set. |
| 404 on `/api/v1/...` | Wrong base URL (e.g. missing `/api/v1`) or server not mounted at `/api/v1`. |
| CORS errors in browser | Backend CORS allows your frontend origin; in `.env`, `CORS_ORIGINS` can include `http://localhost:8081` (and the port Flutter web uses). |
| DB connection failed | PostgreSQL running; `DATABASE_URL` in `.env` correct; database `tracely_dev` exists. |

---

## 7. One-line smoke test (after backend is up)

```bash
# No auth – should return 401 or 400, not connection error
curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/api/v1/workspaces
# Expected: 401

# With auth (after LOGIN and setting TOKEN)
curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/api/v1/workspaces -H "Authorization: Bearer $TOKEN"
# Expected: 200
```

If the first returns 401 and the second 200, the server and auth are working.
