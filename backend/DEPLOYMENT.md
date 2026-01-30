# Deployment Guide

This guide covers deploying Tracely backend to various platforms.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Local Deployment](#local-deployment)
3. [Docker Deployment](#docker-deployment)
4. [Cloud Deployment](#cloud-deployment)
   - [AWS](#aws-deployment)
   - [Google Cloud Platform](#gcp-deployment)
   - [Azure](#azure-deployment)
   - [Heroku](#heroku-deployment)
   - [DigitalOcean](#digitalocean-deployment)
5. [Kubernetes Deployment](#kubernetes-deployment)
6. [Environment Variables](#environment-variables)
7. [Database Setup](#database-setup)
8. [SSL/TLS Setup](#ssltls-setup)
9. [Monitoring & Logging](#monitoring--logging)

## Prerequisites

- Go 1.22+
- PostgreSQL 14+
- Domain name (for production)
- SSL certificate (for HTTPS)

## Local Deployment

For local development/testing:

```bash
# 1. Setup
make setup

# 2. Configure .env
cp .env.example .env
# Edit .env with your settings

# 3. Run
make run
```

## Docker Deployment

### Using Docker Compose (Recommended for testing)

```bash
# Start everything
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

### Using Docker Only

```bash
# Build image
docker build -t tracely-backend:latest .

# Run PostgreSQL
docker run -d \
  --name tracely-postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=tracely_dev \
  -p 5432:5432 \
  postgres:15-alpine

# Run backend
docker run -d \
  --name tracely-backend \
  --link tracely-postgres:postgres \
  -e DATABASE_URL=postgres://postgres:postgres@postgres:5432/tracely_dev?sslmode=disable \
  -e JWT_SECRET=your-secret-key \
  -e ENVIRONMENT=production \
  -p 8080:8080 \
  tracely-backend:latest
```

## Cloud Deployment

### AWS Deployment

#### Option 1: EC2 + RDS

**1. Create RDS PostgreSQL Instance**

```bash
aws rds create-db-instance \
  --db-instance-identifier tracely-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --master-username postgres \
  --master-user-password YOUR_SECURE_PASSWORD \
  --allocated-storage 20 \
  --vpc-security-group-ids sg-xxxxx
```

**2. Launch EC2 Instance**

```bash
# Launch Ubuntu instance
aws ec2 run-instances \
  --image-id ami-xxxxx \
  --count 1 \
  --instance-type t3.micro \
  --key-name your-key \
  --security-group-ids sg-xxxxx
```

**3. Deploy to EC2**

SSH into your instance:

```bash
ssh -i your-key.pem ubuntu@your-ec2-ip

# Install Go
wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Clone and build
git clone <your-repo>
cd tracely-backend
go build -o tracely main.go

# Create systemd service
sudo nano /etc/systemd/system/tracely.service
```

Create service file:

```ini
[Unit]
Description=Tracely Backend
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/tracely-backend
ExecStart=/home/ubuntu/tracely-backend/tracely
Restart=on-failure
Environment="DATABASE_URL=postgres://postgres:PASSWORD@your-rds-endpoint:5432/tracely?sslmode=require"
Environment="JWT_SECRET=your-secret"
Environment="ENVIRONMENT=production"
Environment="PORT=8080"

[Install]
WantedBy=multi-user.target
```

Start service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable tracely
sudo systemctl start tracely
```

#### Option 2: AWS Elastic Beanstalk

Create `Dockerrun.aws.json`:

```json
{
  "AWSEBDockerrunVersion": "1",
  "Image": {
    "Name": "your-ecr-repo/tracely-backend:latest",
    "Update": "true"
  },
  "Ports": [
    {
      "ContainerPort": 8080,
      "HostPort": 8080
    }
  ]
}
```

Deploy:

```bash
eb init -p docker tracely-backend
eb create tracely-production
eb deploy
```

#### Option 3: AWS ECS

1. Push Docker image to ECR
2. Create ECS task definition
3. Create ECS service
4. Configure Application Load Balancer

### GCP Deployment

#### Option 1: Cloud Run (Easiest)

```bash
# Build and push to Container Registry
gcloud builds submit --tag gcr.io/YOUR_PROJECT/tracely-backend

# Deploy
gcloud run deploy tracely-backend \
  --image gcr.io/YOUR_PROJECT/tracely-backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars DATABASE_URL=postgres://...,JWT_SECRET=... \
  --add-cloudsql-instances YOUR_PROJECT:REGION:INSTANCE
```

#### Option 2: GKE (Kubernetes)

See [Kubernetes Deployment](#kubernetes-deployment) section.

### Azure Deployment

#### Option 1: Azure Container Instances

```bash
# Create resource group
az group create --name tracely-rg --location eastus

# Create PostgreSQL
az postgres flexible-server create \
  --name tracely-db \
  --resource-group tracely-rg \
  --location eastus \
  --admin-user postgres \
  --admin-password YOUR_PASSWORD \
  --sku-name Standard_B1ms

# Deploy container
az container create \
  --resource-group tracely-rg \
  --name tracely-backend \
  --image your-registry/tracely-backend:latest \
  --dns-name-label tracely \
  --ports 8080 \
  --environment-variables \
    DATABASE_URL=postgres://... \
    JWT_SECRET=your-secret \
    ENVIRONMENT=production
```

#### Option 2: Azure App Service

```bash
# Create App Service plan
az appservice plan create \
  --name tracely-plan \
  --resource-group tracely-rg \
  --is-linux

# Create web app
az webapp create \
  --resource-group tracely-rg \
  --plan tracely-plan \
  --name tracely-backend \
  --deployment-container-image-name your-registry/tracely-backend:latest

# Configure environment variables
az webapp config appsettings set \
  --resource-group tracely-rg \
  --name tracely-backend \
  --settings \
    DATABASE_URL=postgres://... \
    JWT_SECRET=your-secret
```

### Heroku Deployment

```bash
# Create Heroku app
heroku create tracely-backend

# Add PostgreSQL
heroku addons:create heroku-postgresql:hobby-dev

# Set environment variables
heroku config:set JWT_SECRET=your-secret
heroku config:set ENVIRONMENT=production

# Deploy
git push heroku main
```

Create `Procfile`:

```
web: ./tracely-backend
```

### DigitalOcean Deployment

#### Option 1: App Platform

1. Connect your GitHub repository
2. Configure build:
   - Build Command: `go build -o tracely-backend main.go`
   - Run Command: `./tracely-backend`
3. Add PostgreSQL database
4. Set environment variables
5. Deploy

#### Option 2: Droplet

```bash
# Create droplet
doctl compute droplet create tracely \
  --size s-1vcpu-1gb \
  --image ubuntu-22-04-x64 \
  --region nyc1

# SSH and deploy (similar to EC2 instructions)
```

## Kubernetes Deployment

### 1. Create ConfigMap

`k8s/configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: tracely-config
data:
  ENVIRONMENT: "production"
  PORT: "8080"
  CORS_ORIGINS: "https://tracely.com"
```

### 2. Create Secret

```bash
kubectl create secret generic tracely-secrets \
  --from-literal=database-url='postgres://...' \
  --from-literal=jwt-secret='your-secret'
```

### 3. Create Deployment

`k8s/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tracely-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: tracely-backend
  template:
    metadata:
      labels:
        app: tracely-backend
    spec:
      containers:
      - name: tracely-backend
        image: your-registry/tracely-backend:latest
        ports:
        - containerPort: 8080
        envFrom:
        - configMapRef:
            name: tracely-config
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: tracely-secrets
              key: database-url
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: tracely-secrets
              key: jwt-secret
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

### 4. Create Service

`k8s/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: tracely-backend-service
spec:
  selector:
    app: tracely-backend
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: LoadBalancer
```

### 5. Deploy

```bash
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

## Environment Variables

### Required

- `DATABASE_URL`: PostgreSQL connection string
- `JWT_SECRET`: Secret key for JWT signing

### Optional

- `ENVIRONMENT`: `development` or `production` (default: `development`)
- `PORT`: Server port (default: `8080`)
- `JWT_EXPIRATION`: Token expiration time (default: `1h`)
- `REFRESH_EXPIRATION`: Refresh token expiration (default: `720h`)
- `CORS_ORIGINS`: Allowed origins (comma-separated)
- `LOG_LEVEL`: Logging level (default: `info`)

## Database Setup

### Managed Databases

**AWS RDS**:
```bash
aws rds create-db-instance \
  --db-instance-identifier tracely-db \
  --engine postgres \
  --db-instance-class db.t3.micro \
  --allocated-storage 20
```

**GCP Cloud SQL**:
```bash
gcloud sql instances create tracely-db \
  --database-version=POSTGRES_14 \
  --tier=db-f1-micro \
  --region=us-central1
```

**Azure Database**:
```bash
az postgres flexible-server create \
  --name tracely-db \
  --resource-group tracely-rg
```

### Migrations

Migrations run automatically on startup. No manual intervention needed.

## SSL/TLS Setup

### Using Let's Encrypt + Nginx

```nginx
server {
    listen 80;
    server_name api.tracely.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.tracely.com;

    ssl_certificate /etc/letsencrypt/live/api.tracely.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.tracely.com/privkey.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Get certificate:

```bash
sudo certbot --nginx -d api.tracely.com
```

## Monitoring & Logging

### Application Logs

Logs are written to stdout. Configure log aggregation:

**CloudWatch (AWS)**:
```bash
aws logs create-log-group --log-group-name /tracely/backend
```

**Stackdriver (GCP)**:
Automatic with Cloud Run/GKE

**Azure Monitor**:
```bash
az monitor log-analytics workspace create \
  --resource-group tracely-rg \
  --workspace-name tracely-logs
```

### Health Checks

Endpoint: `GET /health`

Use for:
- Load balancer health checks
- Kubernetes liveness/readiness probes
- Monitoring systems

### Metrics

Consider integrating:
- Prometheus for metrics
- Grafana for dashboards
- Jaeger for distributed tracing

## Production Checklist

- [ ] Set strong `JWT_SECRET`
- [ ] Use managed PostgreSQL database
- [ ] Enable SSL/TLS
- [ ] Set up automated backups
- [ ] Configure monitoring and alerting
- [ ] Set up log aggregation
- [ ] Enable rate limiting
- [ ] Set up CI/CD pipeline
- [ ] Configure auto-scaling
- [ ] Test disaster recovery
- [ ] Document runbooks
- [ ] Set up status page

## Troubleshooting

### Database Connection Issues

```bash
# Test connection
psql "postgres://user:pass@host:5432/dbname?sslmode=require"

# Check firewall rules
# Ensure backend can reach database
```

### Performance Issues

```bash
# Check resource usage
docker stats tracely-backend

# Enable profiling
go tool pprof http://localhost:8080/debug/pprof/profile
```

### SSL Certificate Issues

```bash
# Verify certificate
openssl s_client -connect api.tracely.com:443 -servername api.tracely.com

# Renew Let's Encrypt
sudo certbot renew
```

## Scaling

### Horizontal Scaling

- Run multiple instances behind load balancer
- Use managed Kubernetes (EKS, GKE, AKS)
- Implement session affinity if needed

### Database Scaling

- Enable connection pooling (already configured)
- Use read replicas for read-heavy workloads
- Consider sharding for very large datasets

### Caching

Consider adding:
- Redis for session storage
- CDN for static assets
- Database query caching

## Support

For deployment issues, check:
- Application logs
- Database logs
- Load balancer logs
- System resources (CPU, memory, disk)

Good luck with your deployment! 🚀
