# Backend Development Guide - Go

## Project Information

**Project Name:** Unified API Debugging, Distributed Tracing and Scenario Automation Platform  
**Frontend:** Flutter Web (Tracely)  
**Backend:** Go (To be built)  
**Frontend Build Date:** January 30, 2026

---

## Quick Start for Backend Development

### What You Need to Know

1. **The frontend is already built and ready** - You don't need to wait for frontend changes
2. **API contracts are defined** - Follow the API documentation provided
3. **The frontend can be tested independently** - Using mock/test servers
4. **You can build the backend independently** - The frontend doesn't need to be running during backend development

---

## Files Provided

### 1. **BACKEND_API_DOCUMENTATION.md**
Complete API documentation including:
- All required endpoints
- Request/Response formats
- Error handling
- Data models
- Database schema suggestions

### 2. **openapi.yaml**
OpenAPI 3.0 specification for:
- Auto-generating API client code
- Testing with Swagger UI
- Integration with API documentation tools
- Static analysis

### 3. **Frontend Web Build**
Location: `frontend_1/build/web/`

View locally:
```bash
cd frontend_1/build/web
python -m http.server 8000
# Open http://localhost:8000
```

---

## Backend Technology Stack - Go

### Recommended Setup

```
Go 1.22+
├── HTTP Framework: Gin or Echo
├── Database: PostgreSQL
├── Tracing: Jaeger or OpenTelemetry
├── Logging: zap or logrus
├── Authentication: JWT
├── CORS: gin-contrib/cors
└── Testing: testify, gotest
```

### Project Structure
```
backend/
├── main.go
├── config/
├── handlers/
│   ├── auth.go
│   ├── workspaces.go
│   ├── collections.go
│   ├── requests.go
│   ├── traces.go
│   ├── monitoring.go
│   ├── governance.go
│   └── settings.go
├── models/
├── services/
├── repositories/
├── middlewares/
├── database/
├── utils/
├── tests/
└── docker/
```

---

## API Overview

### Core Modules

1. **Authentication** (5 endpoints)
   - Login, Register, Logout, Refresh Token, Verify Token

2. **Workspaces** (5 endpoints)
   - CRUD operations for workspaces

3. **Collections** (3 endpoints)
   - Create, Read, List collections

4. **Requests** (3 endpoints)
   - Create, Execute, View History

5. **Tracing** (2 endpoints)
   - Get traces, Get trace details

6. **Monitoring** (1 endpoint)
   - Dashboard data

7. **Governance** (1 endpoint)
   - Policies management

8. **Settings** (2 endpoints)
   - Get/Update user settings

### Total: ~22 API Endpoints

---

## Frontend Features (What to Support)

The frontend has these screens, each requiring backend support:

1. **Landing Screen** - Public welcome page
2. **Auth Screen** - Login/Register
3. **Home Screen** - Dashboard
4. **Workspaces Screen** - List and manage workspaces
5. **Request Studio** - Build and execute API requests
6. **Collections** - Organize requests
7. **Monitoring** - Real-time monitoring dashboard
8. **Governance** - Policy management
9. **Settings** - User preferences

---

## Development Checklist

### Phase 1: Project Setup
- [ ] Initialize Go project
- [ ] Set up database (PostgreSQL recommended)
- [ ] Configure environment variables
- [ ] Set up logging
- [ ] Create database schema

### Phase 2: Core API
- [ ] Implement authentication (JWT)
- [ ] Create User model and repository
- [ ] Create Workspace CRUD
- [ ] Create Collection CRUD
- [ ] Implement middleware (auth, error handling, CORS)

### Phase 3: Request Management
- [ ] Create Request model
- [ ] Implement request storage
- [ ] Build request execution engine
- [ ] Add execution history tracking

### Phase 4: Tracing & Monitoring
- [ ] Integrate Jaeger/OpenTelemetry
- [ ] Implement trace storage
- [ ] Create span models
- [ ] Build monitoring dashboard API

### Phase 5: Advanced Features
- [ ] Implement governance policies
- [ ] Add user settings management
- [ ] Add analytics
- [ ] Optimize performance

### Phase 6: Testing & Deployment
- [ ] Unit tests
- [ ] Integration tests
- [ ] Docker setup
- [ ] CI/CD pipeline
- [ ] Deploy to staging

---

## Testing the Backend

### With Frontend
1. Start Go backend: `go run main.go`
2. Open frontend web build: `http://localhost:8000`
3. Backend should be at: `http://localhost:8080`

### With Swagger/Postman
1. Import `openapi.yaml` into Swagger UI or Postman
2. Test endpoints directly without frontend
3. Use mock data for testing

### Generate API Client
```bash
# From openapi.yaml
npx @openapitools/openapi-generator-cli generate -i openapi.yaml -g go -o ./generated-client
```

---

## Database Schema

### Essential Tables
- **users** - User accounts
- **workspaces** - Workspaces
- **workspace_members** - Membership
- **collections** - Collections
- **requests** - Stored requests
- **executions** - Execution history
- **traces** - Distributed traces
- **spans** - Trace spans
- **policies** - Governance policies

---

## Frontend Configuration

The frontend expects the backend at:
```
http://localhost:8080  (Development)
https://api.tracely.com (Production)
```

This can be configured in the frontend environment variables.

---

## CORS Configuration

The backend needs to allow requests from:
```
http://localhost:3000  (Local dev)
http://localhost:8000  (Web build)
https://tracely.com    (Production)
```

---

## Error Handling

Standard error response format:
```json
{
  "error": "Error message",
  "error_code": "ERROR_CODE",
  "details": "Additional info",
  "timestamp": "2026-01-30T10:00:00Z"
}
```

---

## Authentication

All endpoints use JWT Bearer tokens:
```
Authorization: Bearer {jwt_token}
```

Token expiration: 1 hour (recommended)
Refresh token: 30 days (recommended)

---

## Performance Considerations

- Use database indexes on frequently queried fields
- Implement caching for monitoring dashboard
- Paginate list endpoints (default: 50 items)
- Use connection pooling
- Add request timeouts
- Monitor API response times

---

## Documentation

- **API Details:** BACKEND_API_DOCUMENTATION.md
- **OpenAPI Spec:** openapi.yaml
- **Frontend Location:** frontend_1/build/web/

---

## Support & References

- OpenAPI Specification: `openapi.yaml`
- API Endpoints: `BACKEND_API_DOCUMENTATION.md`
- Frontend Screenshots: Check `frontend_1/lib/screens/`

---

## Next Steps

1. **Clone/Setup Backend Repository**
   ```bash
   mkdir backend
   cd backend
   go mod init tracely-backend
   ```

2. **Review API Specifications**
   - Read `BACKEND_API_DOCUMENTATION.md`
   - Import `openapi.yaml` into Swagger UI

3. **Set Up Database**
   ```bash
   # PostgreSQL
   createdb tracely_dev
   ```

4. **Start Implementing**
   - Begin with authentication
   - Move to workspace management
   - Then request handling
   - Finally, tracing & monitoring

5. **Test Integration**
   - Start backend server
   - Open frontend web build
   - Test complete workflows

---

## Timeline Estimate

- **Phase 1 (Setup):** 1-2 days
- **Phase 2 (Core API):** 3-4 days
- **Phase 3 (Requests):** 2-3 days
- **Phase 4 (Tracing):** 4-5 days
- **Phase 5 (Advanced):** 3-4 days
- **Phase 6 (Testing):** 2-3 days

**Total Estimate:** 15-21 days for MVP

---

## Good Luck! 🚀

The frontend is ready and waiting for the backend. Build independently, follow the API specs, and we'll have a complete platform!

For clarifications, refer to the API documentation and OpenAPI spec.
