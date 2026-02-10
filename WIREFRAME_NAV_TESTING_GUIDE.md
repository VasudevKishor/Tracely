# How to Test Each Section in the Wireframe Nav (UI)

Use the **bottom nav bar** (grey bar with “WIREFRAME NAV:” and a **menu icon**). Tap the **menu icon** to open a list of sections, then pick one to switch screens.

**Before testing most sections:** Log in and select a workspace (see steps below).

---

## 1. Open the app and the nav

1. Start backend: `cd backend && go run main.go`
2. Start app: `cd frontend_1 && flutter run -d chrome` (or your device)
3. In the app, at the **bottom**, find **“WIREFRAME NAV:”** and the **☰ menu icon**
4. Tap the **menu icon** to see: LANDING, AUTH, HOME, WORKSPACES, STUDIO, COLLECTIONS, MONITORING, REPLAY, TRACING, GOVERNANCE, SETTINGS

---

## 2. LANDING (index 0)

- **What it is:** Marketing/landing page.
- **How to test:** Open nav → choose **LANDING**. You should see the Tracely landing with hero, features, CTA. Use “Get Started” / “Sign In” to go to auth (or switch to AUTH via nav).

---

## 3. AUTH (index 1)

- **What it is:** Login and register.
- **How to test:**
  1. Nav → **AUTH**
  2. **Login:** Email `admin@tracely.com`, Password `admin123` → **Login**. You should see a success snackbar and stay on the app.
  3. **Register:** Switch to “Sign up”, fill Name / Email / Password → **Sign up**. You should get a success message (and can then log in with that email/password).

---

## 4. HOME (index 2)

- **What it is:** Dashboard for the selected workspace (overview, quick stats).
- **How to test:**
  1. Be **logged in** (AUTH).
  2. **Select a workspace** (see WORKSPACES below) so “selected workspace” is set.
  3. Nav → **HOME**. Dashboard loads for that workspace (may show “Select a workspace” if none selected).
  4. Use the green **“Check Backend”** FAB (bottom right): tap it → you should see “✅ Backend is reachable!” if the API is up and token is valid.

---

## 5. WORKSPACES (index 3)

- **What it is:** List, create, select workspaces.
- **How to test:**
  1. Be **logged in**. Nav → **WORKSPACES**.
  2. You should see your workspaces (e.g. “Default Workspace” from seed user).
  3. **Select workspace:** Tap a workspace card/list item so it becomes the “selected” one (used by HOME, COLLECTIONS, etc.).
  4. **Create workspace:** Use the “Create workspace” / “+” action → enter name (and optional description) → save. New workspace appears in the list.

---

## 6. STUDIO (index 4) – Request Studio

- **What it is:** Build and send API requests (method, URL, headers, body, execute).
- **How to test:**
  1. Be logged in; select a workspace.
  2. Nav → **STUDIO**.
  3. Set **method** (e.g. GET) and **URL** (e.g. `https://httpbin.org/get`).
  4. Optionally add headers, query params, or body.
  5. Tap **Send** / **Execute**. Response panel should show status and body (or error). You can also save to a collection if that option is available.

---

## 7. COLLECTIONS (index 5)

- **What it is:** API collections and requests inside a workspace.
- **How to test:**
  1. Be logged in; **select a workspace** (WORKSPACES).
  2. Nav → **COLLECTIONS**.
  3. **Create collection:** Use “Create collection” / “+” → name (and optional description) → save. New collection appears.
  4. **Open a collection** → add or view **requests** (if the UI exposes “Add request” or similar). Create a request (method, URL, etc.) and save.
  5. Refresh or re-open COLLECTIONS to see the list from the backend.

---

## 8. MONITORING (index 6)

- **What it is:** Workspace metrics / health (dashboard, topology, etc.).
- **How to test:**
  1. Be logged in; select a workspace.
  2. Nav → **MONITORING**.
  3. Screen loads metrics for the selected workspace (or fallback/mock data if API fails). You may see dashboard cards, topology, or tabs – click around to test each visible block.

---

## 9. REPLAY (index 7)

- **What it is:** Create and run request replays.
- **How to test:**
  1. Be logged in; select a workspace.
  2. Nav → **REPLAY**.
  3. If it says “Please select a workspace first”, go to WORKSPACES and select one, then come back.
  4. **Create replay:** Use “Create replay” / “+” → fill form (e.g. name, source trace, target environment) → save.
  5. **Execute replay:** Tap a replay card → “Execute” (confirm if asked). You should see success or error feedback.
  6. **Note:** Replay list is only populated from the backend if the app calls the “list replays” API; otherwise the list may be empty until you add that call.

---

## 10. TRACING (index 8)

- **What it is:** Distributed traces and span details.
- **How to test:**
  1. Be logged in; select a workspace.
  2. Nav → **TRACING** (or **TRACES**).
  3. List of traces loads for the workspace (may be empty if no traces yet).
  4. **Tap a trace** → trace detail screen with spans, timeline, etc.
  5. Use **Refresh** (if shown) to reload the list. Creating and executing requests in STUDIO (or replays) may create traces depending on backend behavior.

---

## 11. GOVERNANCE (index 9)

- **What it is:** Policies and governance rules for the workspace.
- **How to test:**
  1. Be logged in; select a workspace.
  2. Nav → **GOVERNANCE**.
  3. **List policies:** Existing policies for the workspace are shown.
  4. **Create policy:** Use “Create policy” / “+” → name, description, type (e.g. security) → save. New policy appears in the list.
  5. **Edit/delete:** Use per-policy actions if the UI exposes them.

---

## 12. SETTINGS (index 10)

- **What it is:** User/profile and app settings (tabs: Profile, Team, API Keys, etc.).
- **How to test:**
  1. Nav → **SETTINGS** (works without workspace; login may or may not be required depending on implementation).
  2. Switch between tabs (Profile, Team, API Keys, Integrations, Billing, Security).
  3. Change any editable fields and save if there’s a save button; confirm values persist or show success/error.

---

## Quick checklist (order that avoids “select workspace” errors)

| Order | Nav item      | Action |
|-------|---------------|--------|
| 1     | **AUTH**      | Log in with `admin@tracely.com` / `admin123` |
| 2     | **WORKSPACES**| Select “Default Workspace” (or any workspace) |
| 3     | **HOME**      | Confirm dashboard; tap green FAB → “Backend is reachable!” |
| 4     | **COLLECTIONS** | Create a collection, then add a request if UI allows |
| 5     | **STUDIO**    | Send a GET request (e.g. to https://httpbin.org/get) |
| 6     | **MONITORING**| Confirm metrics/topology load |
| 7     | **REPLAY**    | Create a replay, then execute it |
| 8     | **TRACING**   | Open trace list and a trace detail |
| 9     | **GOVERNANCE**| Create a policy |
| 10    | **SETTINGS**  | Open each settings tab |

---

## If something doesn’t load

- **“Please select a workspace first”** → Go to **WORKSPACES**, tap a workspace to select it, then return to the screen.
- **“You need to login first”** → Go to **AUTH** and log in (or register then log in).
- **Backend errors / no data** → Ensure backend is running on port **8081** and the app’s base URL is `http://localhost:8081/api/v1` (or your machine IP for a device). Use the green **Check Backend** FAB on HOME to verify.
