#!/bin/bash
# RakshaPoorvak - Health check script
# Verifies that all components are properly set up and running
# Run from project root: ./scripts/healthcheck.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
WARN=0
FAIL=0

check_pass() {
    echo -e "${GREEN}✔ $1${NC}"
    ((PASS++))
}

check_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
    ((WARN++))
}

check_fail() {
    echo -e "${RED}✖ $1${NC}"
    ((FAIL++))
}

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  RakshaPoorvak Health Check${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Database
echo -e "${BLUE}[Database]${NC}"

if docker ps 2>/dev/null | grep -q raksha-postgres; then
    check_pass "PostgreSQL container is running"

    # Try to connect
    export PGPASSWORD=dev_password
    if psql -h localhost -p 25432 -U rakshapoorvak -d rakshapoorvak_dev -c "SELECT 1" &> /dev/null; then
        check_pass "Database connection successful"

        # Check for tables
        TABLE_COUNT=$(psql -h localhost -p 25432 -U rakshapoorvak -d rakshapoorvak_dev -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'" 2>/dev/null | tr -d ' ')
        if [ "$TABLE_COUNT" -gt 0 ] 2>/dev/null; then
            check_pass "Database has $TABLE_COUNT tables"
        else
            check_warn "Database has no tables (run backend to apply migrations)"
        fi

        # Check for seed data
        USER_COUNT=$(psql -h localhost -p 25432 -U rakshapoorvak -d rakshapoorvak_dev -t -c "SELECT COUNT(*) FROM users" 2>/dev/null | tr -d ' ' || echo "0")
        if [ "$USER_COUNT" -gt 0 ] 2>/dev/null; then
            check_pass "Demo data seeded ($USER_COUNT users)"
        else
            check_warn "No demo data found (run ./scripts/seed-all.sh)"
        fi
    else
        check_fail "Cannot connect to database"
    fi
else
    check_fail "PostgreSQL container is not running"
    echo "  Run: docker compose -f docker-compose.raksha-db.yml up -d"
fi

echo ""

# Backend
echo -e "${BLUE}[Backend]${NC}"

if [ -f "$PROJECT_ROOT/backend/pom.xml" ]; then
    check_pass "Backend project exists"

    if [ -d "$PROJECT_ROOT/backend/target/classes" ]; then
        check_pass "Backend is compiled"
    else
        check_warn "Backend not compiled (run: cd backend && mvn compile)"
    fi

    # Check if backend is running
    if curl -s http://localhost:8080/actuator/health &> /dev/null || curl -s http://localhost:8080/api/health &> /dev/null; then
        check_pass "Backend API is running on port 8080"
    else
        if lsof -i :8080 &> /dev/null; then
            check_warn "Port 8080 is in use but health check failed"
        else
            check_warn "Backend is not running (run: cd backend && mvn spring-boot:run)"
        fi
    fi
else
    check_fail "Backend project not found"
fi

echo ""

# Hospital Dashboard
echo -e "${BLUE}[Hospital Dashboard]${NC}"

if [ -f "$PROJECT_ROOT/hospital-dashboard/package.json" ]; then
    check_pass "Hospital Dashboard project exists"

    if [ -d "$PROJECT_ROOT/hospital-dashboard/node_modules" ]; then
        check_pass "npm dependencies installed"
    else
        check_warn "npm dependencies not installed (run: cd hospital-dashboard && npm install)"
    fi

    if [ -f "$PROJECT_ROOT/hospital-dashboard/.env" ]; then
        check_pass ".env file exists"
    else
        check_warn ".env file missing (run: cp hospital-dashboard/.env.example hospital-dashboard/.env)"
    fi

    # Check if dev server is running
    if lsof -i :5173 &> /dev/null; then
        check_pass "Dev server is running on port 5173"
    else
        check_warn "Dev server is not running (run: cd hospital-dashboard && npm run dev)"
    fi
else
    check_fail "Hospital Dashboard project not found"
fi

echo ""

# User App (Flutter)
echo -e "${BLUE}[User App]${NC}"

if [ -f "$PROJECT_ROOT/user-app/pubspec.yaml" ]; then
    check_pass "User App project exists"

    if [ -d "$PROJECT_ROOT/user-app/.dart_tool" ]; then
        check_pass "Flutter dependencies installed"
    else
        check_warn "Flutter dependencies not installed (run: cd user-app && flutter pub get)"
    fi

    if [ -f "$PROJECT_ROOT/user-app/.env" ]; then
        check_pass ".env file exists"
    else
        check_warn ".env file missing (copy from .env.example)"
    fi
else
    check_fail "User App project not found"
fi

echo ""

# Driver App (Flutter)
echo -e "${BLUE}[Driver App]${NC}"

if [ -f "$PROJECT_ROOT/driver-app/pubspec.yaml" ]; then
    check_pass "Driver App project exists"

    if [ -d "$PROJECT_ROOT/driver-app/.dart_tool" ]; then
        check_pass "Flutter dependencies installed"
    else
        check_warn "Flutter dependencies not installed (run: cd driver-app && flutter pub get)"
    fi

    if [ -f "$PROJECT_ROOT/driver-app/.env" ]; then
        check_pass ".env file exists"
    else
        check_warn ".env file missing (copy from .env.example)"
    fi
else
    check_fail "Driver App project not found"
fi

echo ""

# Summary
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${GREEN}Passed:${NC}   $PASS"
echo -e "  ${YELLOW}Warnings:${NC} $WARN"
echo -e "  ${RED}Failed:${NC}   $FAIL"
echo ""

if [ $FAIL -gt 0 ]; then
    echo -e "${RED}Some checks failed. Please fix the issues above.${NC}"
    exit 1
elif [ $WARN -gt 0 ]; then
    echo -e "${YELLOW}Setup is partially complete. See warnings above.${NC}"
    exit 0
else
    echo -e "${GREEN}All checks passed! Your environment is fully set up.${NC}"
    exit 0
fi
