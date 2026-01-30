# Tracely Backend API Documentation

**Project:** Unified API Debugging, Distributed Tracing and Scenario Automation Platform  
**Frontend:** Flutter Web Application  
**Backend:** Go (to be built)  
**Date:** January 30, 2026

---

## Overview

Tracely is a comprehensive API testing, debugging, and distributed tracing platform. This document specifies the API contracts that the Go backend must implement.

---

## Frontend Architecture

The frontend is built with Flutter and consists of the following screens/modules:

1. **Landing Screen** - Initial welcome/information page
2. **Auth Screen** - User authentication (login/signup)
3. **Home Screen** - Dashboard/main hub
4. **Workspaces Screen** - Workspace management
5. **Request Studio Screen** - API request builder and testing
6. **Collections Screen** - Organize and manage API collections
7. **Monitoring Screen** - Real-time monitoring and logs
8. **Governance Screen** - Settings, policies, and governance
9. **Settings Screen** - User preferences and configuration

---

## API Endpoints Required

### 1. Authentication Module

#### Login
```
POST /api/v1/auth/login
Content-Type: application/json

Request:
{
  "email": "user@example.com",
  "password": "password123"
}

Response (200):
{
  "token": "jwt_token_here",
  "user_id": "user_uuid",
  "email": "user@example.com",
  "name": "John Doe"
}

Error (401):
{
  "error": "Invalid credentials"
}
```

#### Signup/Register
```
POST /api/v1/auth/register
Content-Type: application/json

Request:
{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe"
}

Response (201):
{
  "token": "jwt_token_here",
  "user_id": "user_uuid",
  "message": "User created successfully"
}

Error (400):
{
  "error": "Email already exists"
}
```

#### Logout
```
POST /api/v1/auth/logout
Authorization: Bearer {token}

Response (200):
{
  "message": "Logged out successfully"
}
```

#### Refresh Token
```
POST /api/v1/auth/refresh
Content-Type: application/json

Request:
{
  "refresh_token": "refresh_token_here"
}

Response (200):
{
  "token": "new_jwt_token",
  "refresh_token": "new_refresh_token"
}
```

---

### 2. Workspace Management

#### Get All Workspaces
```
GET /api/v1/workspaces
Authorization: Bearer {token}

Response (200):
{
  "workspaces": [
    {
      "id": "workspace_uuid",
      "name": "Default Workspace",
      "description": "Default workspace",
      "owner_id": "user_uuid",
      "created_at": "2026-01-30T10:00:00Z",
      "members": ["user_uuid1", "user_uuid2"]
    }
  ]
}
```

#### Create Workspace
```
POST /api/v1/workspaces
Authorization: Bearer {token}
Content-Type: application/json

Request:
{
  "name": "New Workspace",
  "description": "Description of workspace"
}

Response (201):
{
  "id": "workspace_uuid",
  "name": "New Workspace",
  "owner_id": "user_uuid",
  "created_at": "2026-01-30T10:00:00Z"
}
```

#### Get Workspace Details
```
GET /api/v1/workspaces/{workspace_id}
Authorization: Bearer {token}

Response (200):
{
  "id": "workspace_uuid",
  "name": "Default Workspace",
  "description": "Description",
  "owner_id": "user_uuid",
  "members": [
    {
      "user_id": "user_uuid1",
      "role": "admin"
    }
  ],
  "created_at": "2026-01-30T10:00:00Z"
}
```

#### Update Workspace
```
PUT /api/v1/workspaces/{workspace_id}
Authorization: Bearer {token}
Content-Type: application/json

Request:
{
  "name": "Updated Name",
  "description": "Updated description"
}

Response (200):
{
  "id": "workspace_uuid",
  "name": "Updated Name",
  "updated_at": "2026-01-30T10:00:00Z"
}
```

#### Delete Workspace
```
DELETE /api/v1/workspaces/{workspace_id}
Authorization: Bearer {token}

Response (204): No Content
```

---

### 3. Collections Management

#### Get All Collections
```
GET /api/v1/workspaces/{workspace_id}/collections
Authorization: Bearer {token}

Response (200):
{
  "collections": [
    {
      "id": "collection_uuid",
      "name": "User API",
      "description": "User management APIs",
      "workspace_id": "workspace_uuid",
      "created_at": "2026-01-30T10:00:00Z",
      "request_count": 5
    }
  ]
}
```

#### Create Collection
```
POST /api/v1/workspaces/{workspace_id}/collections
Authorization: Bearer {token}
Content-Type: application/json

Request:
{
  "name": "User API",
  "description": "User management APIs"
}

Response (201):
{
  "id": "collection_uuid",
  "name": "User API",
  "workspace_id": "workspace_uuid",
  "created_at": "2026-01-30T10:00:00Z"
}
```

#### Get Collection Details
```
GET /api/v1/workspaces/{workspace_id}/collections/{collection_id}
Authorization: Bearer {token}

Response (200):
{
  "id": "collection_uuid",
  "name": "User API",
  "description": "User management APIs",
  "requests": [
    {
      "id": "request_uuid",
      "name": "Get Users",
      "method": "GET",
      "url": "https://api.example.com/users"
    }
  ],
  "created_at": "2026-01-30T10:00:00Z"
}
```

---

### 4. Request Studio (API Testing)

#### Create Request
```
POST /api/v1/workspaces/{workspace_id}/collections/{collection_id}/requests
Authorization: Bearer {token}
Content-Type: application/json

Request:
{
  "name": "Get All Users",
  "method": "GET",
  "url": "https://api.example.com/users",
  "headers": {
    "Content-Type": "application/json",
    "Authorization": "Bearer token"
  },
  "query_params": {
    "page": "1",
    "limit": "10"
  },
  "body": null,
  "description": "Fetch all users"
}

Response (201):
{
  "id": "request_uuid",
  "name": "Get All Users",
  "method": "GET",
  "url": "https://api.example.com/users",
  "created_at": "2026-01-30T10:00:00Z"
}
```

#### Execute Request
```
POST /api/v1/workspaces/{workspace_id}/requests/{request_id}/execute
Authorization: Bearer {token}
Content-Type: application/json

Request:
{
  "override_url": null,
  "override_headers": null,
  "trace_id": "trace_uuid"
}

Response (200):
{
  "execution_id": "execution_uuid",
  "status_code": 200,
  "response_time_ms": 145,
  "response_body": {...},
  "response_headers": {...},
  "trace_id": "trace_uuid",
  "timestamp": "2026-01-30T10:00:00Z"
}
```

#### Get Request History
```
GET /api/v1/workspaces/{workspace_id}/requests/{request_id}/history
Authorization: Bearer {token}

Query Parameters:
- limit: 50 (default)
- offset: 0 (default)

Response (200):
{
  "executions": [
    {
      "id": "execution_uuid",
      "status_code": 200,
      "response_time_ms": 145,
      "timestamp": "2026-01-30T10:00:00Z",
      "trace_id": "trace_uuid"
    }
  ],
  "total": 100
}
```

---

### 5. Monitoring & Tracing

#### Get Traces
```
GET /api/v1/workspaces/{workspace_id}/traces
Authorization: Bearer {token}

Query Parameters:
- service_name: (optional)
- start_time: (optional) ISO8601 format
- end_time: (optional) ISO8601 format
- limit: 50 (default)
- offset: 0 (default)

Response (200):
{
  "traces": [
    {
      "trace_id": "trace_uuid",
      "service_name": "user-service",
      "span_count": 5,
      "total_duration_ms": 234,
      "start_time": "2026-01-30T10:00:00Z",
      "status": "success"
    }
  ],
  "total": 150
}
```

#### Get Trace Details
```
GET /api/v1/workspaces/{workspace_id}/traces/{trace_id}
Authorization: Bearer {token}

Response (200):
{
  "trace_id": "trace_uuid",
  "spans": [
    {
      "span_id": "span_uuid",
      "parent_span_id": "parent_span_uuid",
      "operation_name": "db.query",
      "service_name": "user-service",
      "start_time": "2026-01-30T10:00:00.000Z",
      "duration_ms": 123,
      "tags": {
        "db.type": "postgresql",
        "db.query": "SELECT * FROM users"
      },
      "logs": [
        {
          "timestamp": "2026-01-30T10:00:00.000Z",
          "message": "Query executed",
          "level": "info"
        }
      ]
    }
  ]
}
```

#### Get Monitoring Dashboard
```
GET /api/v1/workspaces/{workspace_id}/monitoring/dashboard
Authorization: Bearer {token}

Query Parameters:
- time_range: last_hour, last_24h, last_7d, last_30d (default: last_hour)

Response (200):
{
  "total_requests": 1234,
  "successful_requests": 1200,
  "failed_requests": 34,
  "avg_response_time_ms": 156,
  "p95_response_time_ms": 450,
  "p99_response_time_ms": 890,
  "error_rate": 2.76,
  "top_endpoints": [
    {
      "endpoint": "GET /api/users",
      "count": 234,
      "avg_response_time_ms": 145
    }
  ],
  "services": [
    {
      "name": "user-service",
      "status": "healthy",
      "request_count": 567
    }
  ]
}
```

---

### 6. Governance & Settings

#### Get Governance Policies
```
GET /api/v1/workspaces/{workspace_id}/governance/policies
Authorization: Bearer {token}

Response (200):
{
  "policies": [
    {
      "id": "policy_uuid",
      "name": "Rate Limiting",
      "description": "Maximum 1000 requests per minute",
      "enabled": true,
      "rules": [...]
    }
  ]
}
```

#### Get User Settings
```
GET /api/v1/users/settings
Authorization: Bearer {token}

Response (200):
{
  "theme": "light",
  "notifications_enabled": true,
  "email_notifications": true,
  "language": "en",
  "timezone": "UTC",
  "preferences": {}
}
```

#### Update User Settings
```
PUT /api/v1/users/settings
Authorization: Bearer {token}
Content-Type: application/json

Request:
{
  "theme": "dark",
  "notifications_enabled": true,
  "language": "en"
}

Response (200):
{
  "message": "Settings updated successfully"
}
```

---

## Error Handling

All errors should follow this format:

```json
{
  "error": "Error message",
  "error_code": "ERROR_CODE",
  "details": "Additional details if applicable",
  "timestamp": "2026-01-30T10:00:00Z"
}
```

### HTTP Status Codes

- **200** - OK
- **201** - Created
- **204** - No Content
- **400** - Bad Request
- **401** - Unauthorized
- **403** - Forbidden
- **404** - Not Found
- **500** - Internal Server Error
- **503** - Service Unavailable

---

## Authentication

All endpoints (except `/api/v1/auth/login` and `/api/v1/auth/register`) require:

```
Authorization: Bearer {jwt_token}
```

---

## Frontend Web Build

**Location:** `build/web/` directory  
**To view locally:**
```bash
cd build/web
python -m http.server 8000
# Open http://localhost:8000
```

The frontend expects the Go backend to be running at:
```
http://localhost:8080  (default)
```

Update the base URL in the frontend configuration file when deploying.

---

## Data Models

### User
```json
{
  "id": "uuid",
  "email": "email@example.com",
  "name": "Full Name",
  "created_at": "2026-01-30T10:00:00Z",
  "updated_at": "2026-01-30T10:00:00Z"
}
```

### Workspace
```json
{
  "id": "uuid",
  "name": "Workspace Name",
  "description": "Description",
  "owner_id": "user_uuid",
  "members": ["user_uuid1", "user_uuid2"],
  "created_at": "2026-01-30T10:00:00Z"
}
```

### Collection
```json
{
  "id": "uuid",
  "name": "Collection Name",
  "description": "Description",
  "workspace_id": "workspace_uuid",
  "created_at": "2026-01-30T10:00:00Z"
}
```

### Request
```json
{
  "id": "uuid",
  "name": "Request Name",
  "method": "GET",
  "url": "https://api.example.com/endpoint",
  "headers": {},
  "query_params": {},
  "body": null,
  "collection_id": "collection_uuid",
  "created_at": "2026-01-30T10:00:00Z"
}
```

---

## Database Schema Suggestions

- **users** - User accounts
- **workspaces** - User workspaces
- **workspace_members** - Workspace membership
- **collections** - API collections
- **requests** - Stored API requests
- **executions** - Request execution history
- **traces** - Distributed tracing data
- **spans** - Trace spans
- **policies** - Governance policies

---

## Next Steps

1. Set up Go project structure
2. Implement database models
3. Create REST API endpoints as specified
4. Implement JWT authentication
5. Add distributed tracing support
6. Connect frontend to backend API
7. Deploy and test integration

---

## Notes

- All timestamps should be in ISO 8601 format (UTC)
- Use UUIDs for all entity IDs
- Implement proper error handling and validation
- Add CORS headers for frontend communication
- Use connection pooling for database queries
- Implement request/response logging for monitoring

---

**For questions or clarifications, refer to the frontend screens or this specification.**
