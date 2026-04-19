#!/bin/bash
# RakshaPoorvak – Seed all demo data (MGM Hospital Navi Mumbai)
# Run from project root: ./scripts/seed-all.sh
#
# All seed files use TRUNCATE RESTART IDENTITY CASCADE, so this script
# is fully idempotent – safe to run multiple times.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SEED_DIR="$PROJECT_ROOT/seed"

DB_NAME="${DB_NAME:-rakshapoorvak_dev}"
DB_USER="${DB_USER:-rakshapoorvak}"
DB_PASSWORD="${DB_PASSWORD:-dev_password}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-25432}"

export PGPASSWORD="$DB_PASSWORD"

echo "=== RakshaPoorvak Data Seeding ==="
echo "Database: $DB_NAME @ $DB_HOST:$DB_PORT"
echo ""

# Ensure backend schema exists (Flyway runs on first backend start)
echo "NOTE: If this is the first run, start the backend once to apply migrations:"
echo "  cd backend && mvn spring-boot:run"
echo ""

# Apply V2 migration if not yet applied (adds doctor specialization, driver license)
MIGRATION_FILE="$PROJECT_ROOT/backend/src/main/resources/db/migration/V2__add_doctor_specialization_driver_license.sql"
if [ -f "$MIGRATION_FILE" ]; then
  echo "Ensuring V2 migration columns exist..."
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$MIGRATION_FILE" 2>/dev/null || true
fi

# Apply V3 migration if not yet applied (links drivers to ambulances)
MIGRATION_V3="$PROJECT_ROOT/backend/src/main/resources/db/migration/V3__link_driver_ambulance.sql"
if [ -f "$MIGRATION_V3" ]; then
  echo "Ensuring V3 migration columns exist..."
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$MIGRATION_V3" 2>/dev/null || true
fi
echo ""

for f in "$SEED_DIR"/0*.sql; do
  if [ -f "$f" ]; then
    echo "Running $(basename "$f")..."
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$f" -v ON_ERROR_STOP=1
  fi
done

echo ""
echo "=== Seeding Complete ==="
echo ""
echo "Demo accounts (password: password123):"
echo "  Patients: patient1@test.com .. patient5@test.com"
echo "  Drivers:  driver1@test.com .. driver4@test.com"
echo "  Staff:    staff@hospital.com"
echo "  Doctors:  doctor1@test.com .. doctor3@test.com"
echo ""
echo "Active SOS events for demo:"
echo "  #13 – Amit Joshi (CREATED, awaiting dispatch)"
echo "  #14 – Rahul Sharma (DRIVER_ENROUTE, live tracking)"
