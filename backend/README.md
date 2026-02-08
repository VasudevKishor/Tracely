# Tracely Backend

Complete Go backend implementation for Tracely - Unified API Debugging, Distributed Tracing and Scenario Automation Platform.

## Features

### Core Modules

1. **Trace Intelligence (M1)**
   - Automatic trace ID generation and propagation
   - Span analysis with latency breakdown
   - Critical path detection
   - Log and metric correlation
   - Service dependency topology mapping
   - Trace governance and privacy controls

2. **Replay Engine (M2)**
   - Request and trace replay
   - Mutation and parameterization
   - Failure injection (timeouts, errors, latency)
   - Stateful session replay
   - Load and stress testing

3. **Mock, Test & Automate (M3)**
   - Automatic mock generation from traces
   - Multi-step workflow automation
   - Contract and schema testing
   - Test data generation

4. **Team Workspace (M4)**
   - Collaborative debugging with annotations
   - Workspace and collection management
   - Role-based access control (RBAC)
   - Secure environment management

5. **Delivery & DevOps Bridge (M5)**
   - CI/CD integration
   - Alerting and notifications
   - Performance reports and insights
   - Import/Export (Postman, OpenTelemetry)

## Tech Stack

- **Language**: Go 1.22+
- **Web Framework**: Gin
- **Database**: PostgreSQL with GORM
- **Authentication**: JWT
- **Tracing**: OpenTelemetry compatible

## Quick Start

### Prerequisites

- Go 1.22 or higher
- PostgreSQL 14 or higher
- Git

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd backend
```

2. Install dependencies:
```bash
go mod download
```

3. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Create the database:
```bash
createdb tracely_dev
```

5. Run the application:
```bash
go run main.go
```

The server will start on `http://localhost:8080`

## Project Structure

```
backend/
├── main.go                 # Application entry point
├── config/                 # Configuration management
│   └── config.go
├── database/               # Database initialization and migrations
│   └── database.go
├── models/                 # Data models
│   └── models.go
├── handlers/               # HTTP request handlers
│   ├── auth_handler.go
│   ├── workspace_handler.go
│   ├── collection_handler.go
│   ├── request_handler.go
│   ├── trace_handler.go
│   ├── monitoring_handler.go
│   ├── governance_handler.go
│   ├── settings_handler.go
│   ├── replay_handler.go
│   └── mock_handler.go
├── services/               # Business logic
│   ├── auth_service.go
│   ├── workspace_service.go
│   ├── collection_service.go
│   ├── request_service.go
│   ├── trace_service.go
│   ├── monitoring_service.go
│   ├── governance_service.go
│   ├── settings_service.go
│   ├── replay_service.go
│   └── mock_service.go
├── middlewares/            # HTTP middlewares
│   ├── auth.go
│   ├── error.go
│   ├── logger.go
│   └── trace.go
├── go.mod                  # Go module dependencies
├── go.sum                  # Dependency checksums
├── .env.example            # Environment variables template
└── README.md               # This file
```

## API Endpoints

### Authentication
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/refresh` - Refresh access token
- `POST /api/v1/auth/logout` - User logout
- `POST /api/v1/auth/verify` - Verify token

### Workspaces
- `GET /api/v1/workspaces` - Get all workspaces
- `POST /api/v1/workspaces` - Create workspace
- `GET /api/v1/workspaces/:id` - Get workspace details
- `PUT /api/v1/workspaces/:id` - Update workspace
- `DELETE /api/v1/workspaces/:id` - Delete workspace

### Collections
- `GET /api/v1/workspaces/:workspace_id/collections` - Get all collections
- `POST /api/v1/workspaces/:workspace_id/collections` - Create collection
- `GET /api/v1/workspaces/:workspace_id/collections/:id` - Get collection
- `PUT /api/v1/workspaces/:workspace_id/collections/:id` - Update collection
- `DELETE /api/v1/workspaces/:workspace_id/collections/:id` - Delete collection

### Requests
- `POST /api/v1/workspaces/:workspace_id/collections/:collection_id/requests` - Create request
- `GET /api/v1/workspaces/:workspace_id/requests/:id` - Get request
- `PUT /api/v1/workspaces/:workspace_id/requests/:id` - Update request
- `DELETE /api/v1/workspaces/:workspace_id/requests/:id` - Delete request
- `POST /api/v1/workspaces/:workspace_id/requests/:id/execute` - Execute request
- `GET /api/v1/workspaces/:workspace_id/requests/:id/history` - Get execution history

### Traces
- `GET /api/v1/workspaces/:workspace_id/traces` - Get traces
- `GET /api/v1/workspaces/:workspace_id/traces/:id` - Get trace details
- `POST /api/v1/workspaces/:workspace_id/traces/:trace_id/annotate` - Add annotation
- `GET /api/v1/workspaces/:workspace_id/traces/:trace_id/critical-path` - Get critical path

### Monitoring
- `GET /api/v1/workspaces/:workspace_id/monitoring/dashboard` - Get dashboard data
- `GET /api/v1/workspaces/:workspace_id/monitoring/metrics` - Get metrics
- `GET /api/v1/workspaces/:workspace_id/monitoring/topology` - Get service topology

### Governance
- `GET /api/v1/workspaces/:workspace_id/governance/policies` - Get policies
- `POST /api/v1/workspaces/:workspace_id/governance/policies` - Create policy
- `PUT /api/v1/workspaces/:workspace_id/governance/policies/:id` - Update policy
- `DELETE /api/v1/workspaces/:workspace_id/governance/policies/:id` - Delete policy

### Replays
- `POST /api/v1/workspaces/:workspace_id/replays` - Create replay
- `GET /api/v1/workspaces/:workspace_id/replays/:id` - Get replay
- `POST /api/v1/workspaces/:workspace_id/replays/:id/execute` - Execute replay
- `GET /api/v1/workspaces/:workspace_id/replays/:id/results` - Get results

### Mocks
- `POST /api/v1/workspaces/:workspace_id/mocks/generate` - Generate mocks from trace
- `GET /api/v1/workspaces/:workspace_id/mocks` - Get all mocks
- `PUT /api/v1/workspaces/:workspace_id/mocks/:id` - Update mock
- `DELETE /api/v1/workspaces/:workspace_id/mocks/:id` - Delete mock

### Settings
- `GET /api/v1/users/settings` - Get user settings
- `PUT /api/v1/users/settings` - Update user settings

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ENVIRONMENT` | Environment (development/production) | development |
| `PORT` | Server port | 8080 |
| `DATABASE_URL` | PostgreSQL connection string | postgres://... |
| `JWT_SECRET` | JWT signing secret | change-in-production |
| `JWT_EXPIRATION` | JWT token expiration | 1h |
| `REFRESH_EXPIRATION` | Refresh token expiration | 720h |
| `CORS_ORIGINS` | Allowed CORS origins | localhost URLs |
| `LOG_LEVEL` | Logging level | info |
| `TRACE_STORAGE_DIR` | Directory for trace storage | ./traces |

## Database

The application uses PostgreSQL with automatic migrations. On startup, the application will:

1. Create all necessary tables
2. Set up indexes for performance
3. Enable UUID extension

### Models

- **User** - User accounts
- **Workspace** - User workspaces
- **WorkspaceMember** - Workspace membership
- **Collection** - API collections
- **Request** - API requests
- **Execution** - Request execution history
- **Trace** - Distributed traces
- **Span** - Trace spans
- **Annotation** - Collaborative comments
- **Policy** - Governance policies
- **UserSettings** - User preferences
- **Replay** - Replay configurations
- **ReplayExecution** - Replay results
- **Mock** - Mock services
- **RefreshToken** - JWT refresh tokens

## Development

### Running in Development Mode

```bash
# With hot reload (requires air)
go install github.com/cosmtrek/air@latest
air

# Without hot reload
go run main.go
```

### Running Tests

```bash
go test ./...
```

### Building for Production

```bash
go build -o backend main.go
```

## Docker Support

```dockerfile
# Dockerfile example
FROM golang:1.22-alpine AS builder

WORKDIR /app
COPY . .
RUN go mod download
RUN go build -o backend main.go

FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/backend .
EXPOSE 8080
CMD ["./backend"]
```

## Security

- Passwords are hashed using bcrypt
- JWT tokens for authentication
- CORS protection
- SQL injection protection via GORM
- Input validation on all endpoints

## Performance

- Connection pooling for database
- Indexed database queries
- Efficient JSON serialization
- Request timeout handling
- Rate limiting ready (can be added)

## Integration with Frontend

The Flutter frontend expects the backend to run at:
- Development: `http://localhost:8080`
- Production: `https://api.tracely.com`

All API endpoints return JSON and follow the OpenAPI specification provided.

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

[Your License Here]

## Support

For issues and questions:
- Open an issue on GitHub
- Contact: development@tracely.com

## Roadmap

- [ ] WebSocket support for real-time updates
- [ ] Advanced metrics and analytics
- [ ] Integration with more CI/CD platforms
- [ ] Kubernetes operator
- [ ] Mobile app support
- [ ] Advanced AI-powered trace analysis
