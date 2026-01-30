# Tracely Backend Setup Guide

This guide will help you set up and run the Tracely backend on your machine.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Go 1.22 or higher**: [Download here](https://golang.org/dl/)
- **PostgreSQL 14 or higher**: [Download here](https://www.postgresql.org/download/)
- **Git**: [Download here](https://git-scm.com/downloads)
- **Make** (optional but recommended): Usually pre-installed on Linux/Mac, [Windows guide](https://gnuwin32.sourceforge.net/packages/make.htm)

## Quick Setup (Using Make)

If you have Make installed, setup is simple:

```bash
# 1. Clone the repository
git clone <repository-url>
cd backend

# 2. Run setup (creates .env, downloads dependencies, creates database)
make setup

# 3. Edit .env file with your configuration
nano .env  # or use your preferred editor

# 4. Run the application
make run
```

That's it! The backend should now be running on `http://localhost:8080`

## Manual Setup (Without Make)

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd backend
```

### Step 2: Create Environment File

```bash
cp .env.example .env
```

Edit `.env` with your preferred editor and configure the following:

```env
ENVIRONMENT=development
PORT=8080
DATABASE_URL=postgres://postgres:YOUR_PASSWORD@localhost:5432/tracely_dev?sslmode=disable
JWT_SECRET=generate-a-secure-random-string-here
CORS_ORIGINS=http://localhost:3000,http://localhost:8000
```

**Important**: Change `JWT_SECRET` to a secure random string. You can generate one using:
```bash
openssl rand -base64 32
```

### Step 3: Install Dependencies

```bash
go mod download
```

### Step 4: Create Database

Using PostgreSQL command line:

```bash
# Login to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE tracely_dev;

# Exit
\q
```

Or using the `createdb` command:

```bash
createdb tracely_dev
```

### Step 5: Run the Application

```bash
go run main.go
```

The application will:
1. Connect to PostgreSQL
2. Run automatic migrations (create tables, indexes)
3. Start the HTTP server on port 8080

You should see output like:
```
Database connection established
Running database migrations...
Database migrations completed successfully
Starting server on port 8080
```

## Docker Setup (Alternative)

If you prefer Docker, you can run everything in containers:

### Prerequisites
- Docker
- Docker Compose

### Steps

1. **Start all services** (PostgreSQL + Backend):
```bash
docker-compose up -d
```

2. **View logs**:
```bash
docker-compose logs -f backend
```

3. **Stop services**:
```bash
docker-compose down
```

The backend will be available at `http://localhost:8080` and PostgreSQL at `localhost:5432`.

Optional PgAdmin (Database UI) will be at `http://localhost:5050` (login: admin@tracely.com / admin)

## Verification

### Check if the server is running:

```bash
curl http://localhost:8080/health
```

Expected response:
```json
{
  "status": "healthy"
}
```

### Test user registration:

```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "name": "Test User"
  }'
```

Expected response (with a JWT token):
```json
{
  "token": "eyJhbGc...",
  "user_id": "...",
  "message": "User created successfully"
}
```

## Frontend Integration

### For Flutter Web Frontend

The Flutter frontend is already built and located in `frontend_1/build/web/`.

To test the full stack:

1. **Start the backend**:
```bash
cd backend
make run
# or
go run main.go
```

2. **Serve the frontend** (in a separate terminal):
```bash
cd frontend_1/build/web
python -m http.server 8000
# or use any static file server
```

3. **Open your browser**:
```
http://localhost:8000
```

The frontend will automatically connect to the backend at `http://localhost:8080`.

## Development Tools

### Install recommended development tools:

```bash
make install-tools
```

This installs:
- **air**: Hot reload for development
- **golangci-lint**: Code linter

### Run with hot reload:

```bash
make dev
# or
air
```

Now any code changes will automatically restart the server.

## Common Issues & Solutions

### Issue: "connection refused" when connecting to database

**Solution**: 
1. Make sure PostgreSQL is running:
```bash
# On Mac
brew services start postgresql

# On Linux
sudo systemctl start postgresql

# On Windows
# Start PostgreSQL service from Services panel
```

2. Verify connection settings in `.env`

### Issue: "database does not exist"

**Solution**:
```bash
createdb tracely_dev
```

### Issue: "bind: address already in use"

**Solution**: Another process is using port 8080. Either:
1. Stop that process
2. Change `PORT` in `.env` to a different port (e.g., 8081)

### Issue: "invalid JWT token"

**Solution**: Make sure you're sending the token in the Authorization header:
```
Authorization: Bearer <your-token>
```

## Database Management

### View database:

```bash
make psql
# or
psql tracely_dev
```

### Reset database (WARNING: Deletes all data):

```bash
make db-reset
```

### Manual migration:

Migrations run automatically on startup. To manually trigger:
```bash
go run main.go
```

## Testing

### Run all tests:

```bash
make test
```

### Run with coverage:

```bash
make test-coverage
```

This generates a `coverage.html` file you can open in your browser.

## Production Deployment

### Build for production:

```bash
make prod-build
```

This creates an optimized binary in `bin/backend`.

### Run in production:

1. Set environment variables:
```bash
export ENVIRONMENT=production
export DATABASE_URL=<production-db-url>
export JWT_SECRET=<secure-secret>
```

2. Run the binary:
```bash
./bin/backend
```

### Using Docker in production:

```bash
docker build -t backend:latest .
docker run -p 8080:8080 \
  -e DATABASE_URL=<production-db-url> \
  -e JWT_SECRET=<secure-secret> \
  -e ENVIRONMENT=production \
  backend:latest
```

## API Documentation

Full API documentation is available in `openapi.yaml`. You can view it using:

### Swagger UI:
1. Go to https://editor.swagger.io/
2. Import the `openapi.yaml` file

### Postman:
1. Import `openapi.yaml` into Postman
2. Use the generated collection to test endpoints

## Getting Help

If you encounter issues:

1. Check the logs for error messages
2. Verify all prerequisites are installed correctly
3. Ensure PostgreSQL is running and accessible
4. Check that ports 8080 (backend) and 5432 (PostgreSQL) are not in use
5. Review the `.env` configuration

## Next Steps

Now that your backend is running:

1. ✅ Backend is running at `http://localhost:8080`
2. ✅ Database is set up and migrated
3. ✅ You can test API endpoints using curl, Postman, or the frontend
4. 📱 Connect your Flutter frontend
5. 🚀 Start building features!

## Useful Commands Cheat Sheet

```bash
# Setup
make setup              # Initial setup
make run                # Run the server
make dev                # Run with hot reload

# Development
make test               # Run tests
make fmt                # Format code
make lint               # Run linter

# Docker
make docker-up          # Start containers
make docker-down        # Stop containers
make docker-logs        # View logs

# Database
make psql               # Connect to DB
make db-reset           # Reset database

# Build
make build              # Development build
make prod-build         # Production build
```

Happy coding! 🎉
