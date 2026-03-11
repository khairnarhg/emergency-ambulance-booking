# RakshaPoorvak Backend

Spring Boot 3.2 backend for the Emergency Ambulance Dispatch & Triage system.

## Prerequisites

- Java 17
- Maven
- PostgreSQL (running)

## Run

```bash
# Ensure JAVA_HOME is set
export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
export PATH="$JAVA_HOME/bin:$PATH"

# Run
mvn spring-boot:run
```

Health check: http://localhost:8080/api/health

## Database

Update `src/main/resources/application-dev.yml` with your PostgreSQL credentials:
- Default: `postgres` user, `postgres` database
- Set `DB_USERNAME` and `DB_PASSWORD` env vars if needed

## Test with Postman

- `GET http://localhost:8080/api/health` – returns `{"status":"UP","application":"RakshaPoorvak Backend"}`
