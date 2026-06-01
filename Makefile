# RakshaPoorvak - Developer Commands
# Usage: make <target>

.PHONY: help setup start-all start-db start-backend start-web stop-all logs seed clean healthcheck

# Default target
help:
	@echo ""
	@echo "RakshaPoorvak - Available Commands"
	@echo "═══════════════════════════════════════════════════════════"
	@echo ""
	@echo "  Setup:"
	@echo "    make setup          Run full setup (first time)"
	@echo "    make healthcheck    Verify everything is working"
	@echo ""
	@echo "  Start Services:"
	@echo "    make start-all      Start database + backend + dashboard"
	@echo "    make start-db       Start PostgreSQL only"
	@echo "    make start-backend  Start Spring Boot backend only"
	@echo "    make start-web      Start hospital dashboard only"
	@echo ""
	@echo "  Stop Services:"
	@echo "    make stop-all       Stop all services"
	@echo "    make stop-db        Stop database container"
	@echo ""
	@echo "  Database:"
	@echo "    make seed           Seed demo data"
	@echo "    make reset-db       Reset database (WARNING: deletes data)"
	@echo "    make psql           Open psql shell to database"
	@echo ""
	@echo "  Development:"
	@echo "    make logs           View backend logs"
	@echo "    make test           Run all tests"
	@echo "    make clean          Clean build artifacts"
	@echo ""

# Setup
setup:
	@./scripts/setup.sh

healthcheck:
	@./scripts/healthcheck.sh

# Start Services
start-all: start-db
	@echo "Starting backend and dashboard..."
	@$(MAKE) -j2 start-backend-bg start-web-bg
	@echo ""
	@echo "Services starting..."
	@echo "  Backend:   http://localhost:8080"
	@echo "  Dashboard: http://localhost:5173"
	@echo ""
	@echo "Use 'make logs' to view output or 'make stop-all' to stop."

start-db:
	@echo "Starting PostgreSQL..."
	@docker compose -f docker-compose.raksha-db.yml up -d
	@echo "Waiting for database..."
	@sleep 2
	@docker exec raksha-postgres pg_isready -U rakshapoorvak -d rakshapoorvak_dev || sleep 3
	@echo "Database ready on port 25432"

start-backend:
	@echo "Starting backend (foreground)..."
	@cd backend && mvn spring-boot:run

start-backend-bg:
	@echo "Starting backend (background)..."
	@cd backend && nohup mvn spring-boot:run > ../logs/backend.log 2>&1 &
	@mkdir -p logs

start-web:
	@echo "Starting hospital dashboard (foreground)..."
	@cd hospital-dashboard && npm run dev

start-web-bg:
	@echo "Starting dashboard (background)..."
	@cd hospital-dashboard && nohup npm run dev > ../logs/dashboard.log 2>&1 &
	@mkdir -p logs

# Stop Services
stop-all: stop-db
	@echo "Stopping backend..."
	@pkill -f "spring-boot:run" 2>/dev/null || true
	@pkill -f "mvn.*rakshapoorvak" 2>/dev/null || true
	@echo "Stopping dashboard..."
	@pkill -f "vite" 2>/dev/null || true
	@echo "All services stopped."

stop-db:
	@echo "Stopping PostgreSQL..."
	@docker compose -f docker-compose.raksha-db.yml down

# Database
seed:
	@./scripts/seed-all.sh

reset-db:
	@echo "WARNING: This will delete all data!"
	@read -p "Are you sure? (y/N) " confirm && [ "$$confirm" = "y" ] || exit 1
	@docker compose -f docker-compose.raksha-db.yml down -v
	@docker compose -f docker-compose.raksha-db.yml up -d
	@echo "Waiting for database..."
	@sleep 5
	@echo "Database reset. Run 'make start-backend' to apply migrations, then 'make seed'."

psql:
	@PGPASSWORD=dev_password psql -h localhost -p 25432 -U rakshapoorvak -d rakshapoorvak_dev

# Development
logs:
	@echo "Backend logs (logs/backend.log):"
	@tail -f logs/backend.log 2>/dev/null || echo "No backend logs found. Start backend with 'make start-all'."

test:
	@echo "Running backend tests..."
	@cd backend && mvn test
	@echo ""
	@echo "Running dashboard tests..."
	@cd hospital-dashboard && npm test 2>/dev/null || echo "No tests configured"

clean:
	@echo "Cleaning build artifacts..."
	@cd backend && mvn clean -q
	@rm -rf hospital-dashboard/node_modules/.cache
	@rm -rf logs/*.log
	@echo "Clean complete."

# Flutter commands (optional)
flutter-setup:
	@echo "Setting up Flutter apps..."
	@cd user-app && flutter pub get
	@cd driver-app && flutter pub get
	@echo "Flutter apps ready."

run-user-app:
	@cd user-app && flutter run

run-driver-app:
	@cd driver-app && flutter run
