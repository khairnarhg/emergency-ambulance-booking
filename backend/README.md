# RakshaPoorvak Backend

Spring Boot 3.2 backend for the Emergency Ambulance Dispatch & Triage system.

## Prerequisites

- Java 17
- Maven
- PostgreSQL 15+

## Quick Start

### 1. Environment Setup

```bash
# From project root - creates DB and user
./scripts/setup-environment.sh
```

### 2. Run Backend

```bash
cd backend
mvn spring-boot:run
```

Flyway will create the schema on first run. Default DB: `rakshapoorvak_dev`, user: `rakshapoorvak`, password: `dev_password`.

### 3. Seed Data (optional)

```bash
# From project root
./scripts/seed-all.sh
```

See `seed/README.md` for test credentials.

## Configuration

Environment variables (or `application-dev.yml`):

| Variable | Default |
|----------|---------|
| DB_HOST | localhost |
| DB_PORT | 5432 |
| DB_NAME | rakshapoorvak_dev |
| DB_USERNAME | rakshapoorvak |
| DB_PASSWORD | dev_password |
| JWT_SECRET | (dev default in yml) |

## API

- Health: `GET /api/health`
- Auth: `POST /api/auth/login`, `POST /api/auth/register`
- Full spec: `docs/BACKEND_TECHNICAL_SPEC.md`

## Test with Postman

1. `GET http://localhost:8080/api/health` – health check
2. `POST http://localhost:8080/api/auth/login` with `{"email":"patient1@test.com","password":"password123"}`
3. Use returned `accessToken` in `Authorization: Bearer <token>` for protected endpoints
