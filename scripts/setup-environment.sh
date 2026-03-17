#!/bin/bash
# RakshaPoorvak – Database connectivity & readiness check
# For Docker (Rancher Desktop): DB is auto-created via docker-compose.raksha-db.yml
# Run from project root: ./scripts/setup-environment.sh

set -e

DB_NAME="${DB_NAME:-rakshapoorvak_dev}"
DB_USER="${DB_USER:-rakshapoorvak}"
DB_PASSWORD="${DB_PASSWORD:-dev_password}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-25432}"

export PGPASSWORD="$DB_PASSWORD"

echo "=== RakshaPoorvak Database Readiness Check ==="
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo "Host: $DB_HOST:$DB_PORT"
echo ""

# a) Verify psql exists
if ! command -v psql &> /dev/null; then
    echo "ERROR: psql not found. Please install PostgreSQL client tools."
    exit 1
fi

# b) Verify connectivity using DB_USER/DB_PASSWORD to DB_NAME
if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; then
    echo "ERROR: Cannot connect to database."
    echo "  Ensure Rancher Desktop is running, then start the DB:"
    echo "    docker compose -f docker-compose.raksha-db.yml up -d"
    echo "  Then re-run this script."
    exit 1
fi

echo "Database is ready."

# c) Success message with JDBC URL and env vars
echo ""
echo "=== Success ==="
echo ""
echo "JDBC URL: jdbc:postgresql://$DB_HOST:$DB_PORT/$DB_NAME"
echo ""
echo "Environment variables:"
echo "  DB_HOST=$DB_HOST"
echo "  DB_PORT=$DB_PORT"
echo "  DB_NAME=$DB_NAME"
echo "  DB_USERNAME=$DB_USER"
echo "  DB_PASSWORD=$DB_PASSWORD"
echo ""
echo "Start backend: cd backend && mvn spring-boot:run"
echo "Flyway will create tables on first run."
