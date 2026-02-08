# API Testing Examples

This document provides curl examples for testing all API endpoints.

## Authentication

### Register a New User

```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "securepassword123",
    "name": "John Doe"
  }'
```

Response:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "message": "User created successfully"
}
```

### Login

```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "securepassword123"
  }'
```

Response:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "john@example.com",
  "name": "John Doe"
}
```

**Save this token for authenticated requests!**

```bash
export TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

## Workspaces

### Get All Workspaces

```bash
curl -X GET http://localhost:8080/api/v1/workspaces \
  -H "Authorization: Bearer $TOKEN"
```

### Create a Workspace

```bash
curl -X POST http://localhost:8080/api/v1/workspaces \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My API Project",
    "description": "Testing APIs for my project"
  }'
```

Save workspace_id from response:
```bash
export WORKSPACE_ID="660e8400-e29b-41d4-a716-446655440000"
```

### Get Workspace Details

```bash
curl -X GET http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID \
  -H "Authorization: Bearer $TOKEN"
```

### Update Workspace

```bash
curl -X PUT http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Workspace Name",
    "description": "Updated description"
  }'
```

## Collections

### Create a Collection

```bash
curl -X POST http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/collections \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "User API",
    "description": "Collection of user-related endpoints"
  }'
```

Save collection_id:
```bash
export COLLECTION_ID="770e8400-e29b-41d4-a716-446655440000"
```

### Get All Collections

```bash
curl -X GET http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/collections \
  -H "Authorization: Bearer $TOKEN"
```

### Get Collection Details

```bash
curl -X GET http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/collections/$COLLECTION_ID \
  -H "Authorization: Bearer $TOKEN"
```

## Requests

### Create a Request

```bash
curl -X POST http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/collections/$COLLECTION_ID/requests \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Get All Users",
    "method": "GET",
    "url": "https://jsonplaceholder.typicode.com/users",
    "headers": {
      "Content-Type": "application/json"
    },
    "query_params": {},
    "body": null,
    "description": "Fetch all users from API"
  }'
```

Save request_id:
```bash
export REQUEST_ID="880e8400-e29b-41d4-a716-446655440000"
```

### Execute a Request

```bash
curl -X POST http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/requests/$REQUEST_ID/execute \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```

Response includes execution results:
```json
{
  "execution_id": "...",
  "status_code": 200,
  "response_time_ms": 145,
  "response_body": "[{...}]",
  "response_headers": "{...}",
  "trace_id": "...",
  "timestamp": "2026-01-30T10:00:00Z"
}
```

### Get Request History

```bash
curl -X GET http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/requests/$REQUEST_ID/history?limit=10 \
  -H "Authorization: Bearer $TOKEN"
```

## Traces

### Get All Traces

```bash
curl -X GET http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/traces?limit=20 \
  -H "Authorization: Bearer $TOKEN"
```

### Get Trace Details

```bash
curl -X GET http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/traces/$TRACE_ID \
  -H "Authorization: Bearer $TOKEN"
```

### Add Annotation to Span

```bash
curl -X POST http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/traces/$TRACE_ID/annotate \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "span_id": "'$SPAN_ID'",
    "comment": "This span is taking too long!",
    "highlight": true
  }'
```

### Get Critical Path

```bash
curl -X GET http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/traces/$TRACE_ID/critical-path \
  -H "Authorization: Bearer $TOKEN"
```

## Monitoring

### Get Dashboard

```bash
curl -X GET "http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/monitoring/dashboard?time_range=last_24h" \
  -H "Authorization: Bearer $TOKEN"
```

Response:
```json
{
  "total_requests": 1234,
  "successful_requests": 1200,
  "failed_requests": 34,
  "avg_response_time_ms": 156.5,
  "p95_response_time_ms": 450.2,
  "p99_response_time_ms": 890.1,
  "error_rate": 2.76,
  "top_endpoints": [...],
  "services": [...]
}
```

### Get Service Topology

```bash
curl -X GET http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/monitoring/topology \
  -H "Authorization: Bearer $TOKEN"
```

## Governance

### Create a Policy

```bash
curl -X POST http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/governance/policies \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Rate Limiting",
    "description": "Limit requests to 1000 per minute",
    "enabled": true,
    "rules": "{\"max_requests\": 1000, \"window\": \"1m\"}"
  }'
```

### Get All Policies

```bash
curl -X GET http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/governance/policies \
  -H "Authorization: Bearer $TOKEN"
```

## Replay

### Create a Replay

```bash
curl -X POST http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/replays \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Production Bug Replay",
    "description": "Replaying production trace in staging",
    "source_trace_id": "'$TRACE_ID'",
    "target_environment": "staging",
    "configuration": {
      "mutations": {},
      "variables": {
        "base_url": "https://staging.example.com"
      }
    }
  }'
```

### Execute Replay

```bash
curl -X POST http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/replays/$REPLAY_ID/execute \
  -H "Authorization: Bearer $TOKEN"
```

### Get Replay Results

```bash
curl -X GET http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/replays/$REPLAY_ID/results \
  -H "Authorization: Bearer $TOKEN"
```

## Mocks

### Generate Mocks from Trace

```bash
curl -X POST http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/mocks/generate \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "trace_id": "'$TRACE_ID'"
  }'
```

### Get All Mocks

```bash
curl -X GET http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/mocks \
  -H "Authorization: Bearer $TOKEN"
```

### Update Mock

```bash
curl -X PUT http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/mocks/$MOCK_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": false,
    "latency": 100
  }'
```

## Settings

### Get User Settings

```bash
curl -X GET http://localhost:8080/api/v1/users/settings \
  -H "Authorization: Bearer $TOKEN"
```

### Update User Settings

```bash
curl -X PUT http://localhost:8080/api/v1/users/settings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "theme": "dark",
    "notifications_enabled": true,
    "email_notifications": false,
    "language": "en",
    "timezone": "America/New_York"
  }'
```

## Complete Workflow Example

Here's a complete workflow from registration to executing a request:

```bash
#!/bin/bash

# 1. Register
REGISTER_RESPONSE=$(curl -s -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "name": "Test User"
  }')

TOKEN=$(echo $REGISTER_RESPONSE | jq -r '.token')
echo "Token: $TOKEN"

# 2. Get workspaces (default workspace created on registration)
WORKSPACES=$(curl -s -X GET http://localhost:8080/api/v1/workspaces \
  -H "Authorization: Bearer $TOKEN")

WORKSPACE_ID=$(echo $WORKSPACES | jq -r '.workspaces[0].id')
echo "Workspace ID: $WORKSPACE_ID"

# 3. Create a collection
COLLECTION=$(curl -s -X POST http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/collections \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Collection",
    "description": "My first collection"
  }')

COLLECTION_ID=$(echo $COLLECTION | jq -r '.id')
echo "Collection ID: $COLLECTION_ID"

# 4. Create a request
REQUEST=$(curl -s -X POST http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/collections/$COLLECTION_ID/requests \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Get Users",
    "method": "GET",
    "url": "https://jsonplaceholder.typicode.com/users",
    "headers": {"Content-Type": "application/json"}
  }')

REQUEST_ID=$(echo $REQUEST | jq -r '.id')
echo "Request ID: $REQUEST_ID"

# 5. Execute the request
EXECUTION=$(curl -s -X POST http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/requests/$REQUEST_ID/execute \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}')

echo "Execution Result:"
echo $EXECUTION | jq '.'

# 6. View execution history
curl -s -X GET http://localhost:8080/api/v1/workspaces/$WORKSPACE_ID/requests/$REQUEST_ID/history \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

Save this as `test_workflow.sh`, make it executable with `chmod +x test_workflow.sh`, and run it!
