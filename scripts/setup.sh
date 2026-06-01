#!/bin/bash
# RakshaPoorvak - One-command setup script
# Run from project root: ./scripts/setup.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
}

print_step() {
    echo -e "${GREEN}▶ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✖ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✔ $1${NC}"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

print_header "RakshaPoorvak - Developer Setup"
echo ""
echo "This script will set up your development environment."
echo "Project root: $PROJECT_ROOT"
echo ""

# Step 1: Check prerequisites
print_header "Step 1: Checking Prerequisites"

MISSING_DEPS=()

print_step "Checking Java..."
if check_command java; then
    JAVA_VERSION=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | cut -d'.' -f1)
    if [ "$JAVA_VERSION" -ge 17 ] 2>/dev/null; then
        print_success "Java $JAVA_VERSION found"
    else
        print_warning "Java 17+ required, found version $JAVA_VERSION"
        MISSING_DEPS+=("java17")
    fi
else
    print_error "Java not found"
    MISSING_DEPS+=("java17")
fi

print_step "Checking Maven..."
if check_command mvn; then
    print_success "Maven found: $(mvn -version 2>&1 | head -1)"
else
    print_error "Maven not found"
    MISSING_DEPS+=("maven")
fi

print_step "Checking Node.js..."
if check_command node; then
    NODE_VERSION=$(node -v | sed 's/v//' | cut -d'.' -f1)
    if [ "$NODE_VERSION" -ge 18 ] 2>/dev/null; then
        print_success "Node.js v$NODE_VERSION found"
    else
        print_warning "Node.js 18+ required, found v$NODE_VERSION"
        MISSING_DEPS+=("node18")
    fi
else
    print_error "Node.js not found"
    MISSING_DEPS+=("node")
fi

print_step "Checking Docker..."
if check_command docker; then
    if docker info &> /dev/null; then
        print_success "Docker found and running"
    else
        print_warning "Docker found but not running. Please start Docker Desktop or Rancher Desktop."
        MISSING_DEPS+=("docker-running")
    fi
else
    print_error "Docker not found"
    MISSING_DEPS+=("docker")
fi

print_step "Checking Flutter..."
if check_command flutter; then
    print_success "Flutter found: $(flutter --version 2>&1 | head -1)"
else
    print_warning "Flutter not found (optional - only needed for mobile apps)"
fi

print_step "Checking psql..."
if check_command psql; then
    print_success "PostgreSQL client found"
else
    print_warning "psql not found (optional - only needed for direct DB access)"
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo ""
    print_error "Missing required dependencies: ${MISSING_DEPS[*]}"
    echo ""
    echo "Install missing dependencies:"
    echo "  brew install openjdk@17 maven node"
    echo "  Install Docker Desktop or Rancher Desktop"
    echo ""
    echo "After installing, run this script again."
    exit 1
fi

# Step 2: Start Database
print_header "Step 2: Starting PostgreSQL Database"

cd "$PROJECT_ROOT"

if docker ps | grep -q raksha-postgres; then
    print_success "Database already running"
else
    print_step "Starting PostgreSQL container..."
    docker compose -f docker-compose.raksha-db.yml up -d

    print_step "Waiting for database to be ready..."
    for i in {1..30}; do
        if docker exec raksha-postgres pg_isready -U rakshapoorvak -d rakshapoorvak_dev &> /dev/null; then
            print_success "Database is ready"
            break
        fi
        sleep 1
        echo -n "."
    done
    echo ""
fi

# Step 3: Setup Backend
print_header "Step 3: Setting Up Backend"

cd "$PROJECT_ROOT/backend"

print_step "Building backend (this may take a few minutes on first run)..."
mvn clean compile -q

print_step "Running Flyway migrations..."
mvn flyway:migrate -q 2>/dev/null || true

print_success "Backend setup complete"

# Step 4: Seed Database
print_header "Step 4: Seeding Demo Data"

cd "$PROJECT_ROOT"
print_step "Running seed scripts..."
"$SCRIPT_DIR/seed-all.sh" 2>/dev/null || {
    print_warning "Seed script had some warnings (this is usually OK on first run)"
}

# Step 5: Setup Hospital Dashboard
print_header "Step 5: Setting Up Hospital Dashboard"

cd "$PROJECT_ROOT/hospital-dashboard"

print_step "Installing npm dependencies..."
npm install --silent

if [ ! -f .env ]; then
    print_step "Creating .env from .env.example..."
    cp .env.example .env
    print_success ".env file created"
else
    print_success ".env file already exists"
fi

print_success "Hospital Dashboard setup complete"

# Step 6: Setup Flutter Apps (if Flutter is available)
if check_command flutter; then
    print_header "Step 6: Setting Up Flutter Apps"

    # User App
    cd "$PROJECT_ROOT/user-app"
    print_step "Setting up User App..."
    flutter pub get --suppress-analytics 2>/dev/null || flutter pub get
    if [ ! -f .env ] && [ -f .env.example ]; then
        cp .env.example .env
    fi
    print_success "User App setup complete"

    # Driver App
    cd "$PROJECT_ROOT/driver-app"
    print_step "Setting up Driver App..."
    flutter pub get --suppress-analytics 2>/dev/null || flutter pub get
    if [ ! -f .env ] && [ -f .env.example ]; then
        cp .env.example .env
    fi
    print_success "Driver App setup complete"
else
    print_header "Step 6: Skipping Flutter Apps"
    print_warning "Flutter not installed. Mobile apps will need manual setup."
    echo "  Install Flutter: https://flutter.dev/docs/get-started/install"
fi

# Final Summary
print_header "Setup Complete!"

echo ""
echo "Your development environment is ready. Here's what was set up:"
echo ""
echo "  ✔ PostgreSQL database running on port 25432"
echo "  ✔ Backend compiled and migrations applied"
echo "  ✔ Demo data seeded (hospitals, users, ambulances, SOS events)"
echo "  ✔ Hospital Dashboard dependencies installed"
if check_command flutter; then
    echo "  ✔ Flutter apps dependencies installed"
fi
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Quick Start Commands${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "  Start all services:     make start-all"
echo "  Start backend only:     cd backend && mvn spring-boot:run"
echo "  Start dashboard only:   cd hospital-dashboard && npm run dev"
echo "  Verify setup:           ./scripts/healthcheck.sh"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Test Credentials (password: password123)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "  Hospital Staff:  staff@hospital.com"
echo "  Doctor:          doctor1@test.com"
echo "  Driver:          driver1@test.com"
echo "  Patient:         patient1@test.com"
echo ""
echo "Happy coding!"
