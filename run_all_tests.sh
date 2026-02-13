#!/usr/bin/env bash
# Run all unit tests: backend (Go) + frontend (Flutter). Optional: API smoke with --api.
# Usage:
#   ./run_all_tests.sh        # run all unit tests
#   ./run_all_tests.sh --api  # unit tests + curl smoke (backend must be up)
# Or from repo root:  make test

set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
API_SMOKE=false
for arg in "$@"; do
  [ "$arg" = "--api" ] && API_SMOKE=true
done

echo "========== Running all unit tests =========="
echo ""

echo "========== 1. Backend (Go) unit tests =========="
cd "$ROOT/backend"
go test ./... -count=1
echo "Backend unit tests: PASSED"
echo ""

echo "========== 2. Frontend (Flutter) unit tests =========="
cd "$ROOT/frontend_1"
flutter test
echo "Frontend unit tests: PASSED"
echo ""

if [ "$API_SMOKE" = true ]; then
  echo "========== 3. API smoke test (optional) =========="
  BASE="http://localhost:8081/api/v1"
  if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "$BASE/workspaces" | grep -q 401; then
    echo "Backend is reachable; unauthenticated request returned 401 as expected."
    # Try register; if user exists, try login instead
    REG=$(curl -s -X POST "$BASE/auth/register" -H "Content-Type: application/json" -d '{"email":"smoke@test.com","password":"password123","name":"Smoke"}')
    if echo "$REG" | grep -q access_token; then
      TOKEN=$(echo "$REG" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
    elif echo "$REG" | grep -q "already exists"; then
      LOGIN=$(curl -s -X POST "$BASE/auth/login" -H "Content-Type: application/json" -d '{"email":"smoke@test.com","password":"password123"}')
      if echo "$LOGIN" | grep -q access_token; then
        TOKEN=$(echo "$LOGIN" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
      fi
    fi
    if [ -n "$TOKEN" ]; then
      CODE=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE/workspaces" -H "Authorization: Bearer $TOKEN")
      [ "$CODE" = "200" ] && echo "Auth + workspaces: OK (200)" || echo "Workspaces returned: $CODE"
    else
      echo "Could not get token (register/login failed)."
    fi
  else
    echo "Backend not reachable at $BASE (start it with: cd backend && go run main.go)"
  fi
  echo ""
fi

echo "========== All unit tests completed =========="
