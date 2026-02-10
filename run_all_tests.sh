#!/usr/bin/env bash
# Run all tests: backend (Go), frontend (Flutter), and optional API smoke test.
# Usage: ./run_all_tests.sh [--api]   (--api = run curl smoke test if backend is up)

set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
API_SMOKE=false
for arg in "$@"; do
  [ "$arg" = "--api" ] && API_SMOKE=true
done

echo "========== 1. Backend (Go) tests =========="
cd "$ROOT/backend"
go test ./... -count=1
echo "Backend tests: PASSED"
echo ""

echo "========== 2. Frontend (Flutter) tests =========="
cd "$ROOT/frontend_1"
flutter test
echo "Frontend tests: PASSED"
echo ""

if [ "$API_SMOKE" = true ]; then
  echo "========== 3. API smoke test (optional) =========="
  BASE="http://localhost:8081/api/v1"
  if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "$BASE/workspaces" | grep -q 401; then
    echo "Backend is reachable; unauthenticated request returned 401 as expected."
    # Optional: register + login + workspaces
    REG=$(curl -s -X POST "$BASE/auth/register" -H "Content-Type: application/json" -d '{"email":"smoke@test.com","password":"password123","name":"Smoke"}')
    if echo "$REG" | grep -q access_token; then
      TOKEN=$(echo "$REG" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
      CODE=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE/workspaces" -H "Authorization: Bearer $TOKEN")
      [ "$CODE" = "200" ] && echo "Auth + workspaces: OK (200)" || echo "Workspaces returned: $CODE"
    else
      echo "Register response (may be 400 if user exists): $REG"
    fi
  else
    echo "Backend not reachable at $BASE (start it with: cd backend && go run main.go)"
  fi
  echo ""
fi

echo "========== All tests completed =========="
