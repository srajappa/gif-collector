# Playwright Screencast Environment Makefile
# Comprehensive development and deployment commands

# Configuration
DOCKER_COMPOSE := docker compose
DOCKER := docker
JUPYTER_SERVICE := jupyter
PROJECT_NAME := playwright-screencast
PYTHON := python3

# Default environment variables
JUPYTER_PORT ?= 8888
HEADLESS_MODE ?= false
LOG_LEVEL ?= INFO

# Colors for terminal output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
WHITE := \033[1;37m
NC := \033[0m # No Color

# Helper function to print colored messages
define print_message
	@echo -e "$(2)[$(1)]$(NC) $(3)"
endef

# Default target - show help
.DEFAULT_GOAL := help

# PHONY targets (targets that don't create files)
.PHONY: help setup build up down restart status logs shell test lint format \
        clean clean-videos clean-all backup health install-dev update-deps \
        demo-youtube demo-google demo-ecommerce demo-all \
        dev prod debug quick-start full-reset ci \
        jupyter-token jupyter-url check-deps validate-env

#==============================================================================
# HELP AND INFORMATION
#==============================================================================

help: ## Show this help message
	$(call print_message,INFO,$(CYAN),Playwright Screencast Environment - Available Commands)
	@echo ""
	$(call print_message,SETUP,$(PURPLE),Project Setup and Build)
	@echo "  setup          - Initialize project (directories, .env, permissions)"
	@echo "  build          - Build Docker images"
	@echo "  rebuild        - Clean build (no cache)"
	@echo "  quick-start    - Complete setup and start (setup + build + up)"
	@echo ""
	$(call print_message,CONTAINER,$(BLUE),Container Management)
	@echo "  up             - Start all services"
	@echo "  down           - Stop all services"
	@echo "  restart        - Restart all services"
	@echo "  status         - Show container status"
	@echo "  logs           - Show real-time logs"
	@echo "  shell          - Open bash shell in container"
	@echo "  jupyter-shell  - Open Jupyter-specific shell"
	@echo ""
	$(call print_message,DEVELOPMENT,$(GREEN),Development Commands)
	@echo "  dev            - Start development environment"
	@echo "  test           - Run test suite"
	@echo "  test-unit      - Run unit tests only"
	@echo "  test-integration - Run integration tests only"
	@echo "  test-coverage  - Run tests with coverage report"
	@echo "  lint           - Run code linting (flake8)"
	@echo "  format         - Format code (black, isort)"
	@echo "  type-check     - Run type checking (mypy)"
	@echo "  install-dev    - Install development dependencies"
	@echo "  update-deps    - Update all dependencies"
	@echo ""
	$(call print_message,DEMOS,$(YELLOW),Demo Examples)
	@echo "  demo-youtube   - Run YouTube trending demo"
	@echo "  demo-google    - Run Google search demo"
	@echo "  demo-ecommerce - Run e-commerce demo"
	@echo "  demo-all       - Run all demos sequentially"
	@echo "  demo-custom    - Run custom demo (set DEMO_URL and DEMO_ACTIONS)"
	@echo ""
	$(call print_message,UTILITIES,$(WHITE),Utilities and Maintenance)
	@echo "  jupyter-token  - Show Jupyter access token"
	@echo "  jupyter-url    - Show Jupyter access URL"
	@echo "  health         - Check system health"
	@echo "  backup         - Backup recordings and logs"
	@echo "  clean          - Remove containers and networks"
	@echo "  clean-videos   - Remove old video recordings"
	@echo "  clean-images   - Remove Docker images"
	@echo "  clean-all      - Complete cleanup"
	@echo "  full-reset     - Nuclear option (clean everything and rebuild)"
	@echo ""
	$(call print_message,VALIDATION,$(CYAN),Validation and Debugging)
	@echo "  validate-env   - Validate environment configuration"
	@echo "  check-deps     - Check system dependencies"
	@echo "  debug          - Start in debug mode with verbose logging"
	@echo "  prod           - Start in production mode"
	@echo "  ci             - Run CI pipeline (test + lint + build)"
	@echo ""
	@echo "Examples:"
	@echo "  make setup && make build && make up"
	@echo "  make quick-start"
	@echo "  make dev"
	@echo "  make demo-all"
	@echo "  make test-coverage"

#==============================================================================
# SETUP AND INITIALIZATION
#==============================================================================

setup: ## Initialize project structure and configuration
	$(call print_message,SETUP,$(PURPLE),Setting up project structure...)
	@chmod +x scripts/*.sh
	@./scripts/setup.sh
	@$(MAKE) validate-env
	$(call print_message,SUCCESS,$(GREEN),Project setup completed!)

validate-env: ## Validate environment configuration
	@echo -e "$(CYAN)[VALIDATE]$(NC) Validating environment..."
	@if [ ! -f .env ]; then \
		echo -e "$(YELLOW)[WARNING]$(NC) Creating .env from template..."; \
		cp .env.example .env; \
	fi
	@if [ ! -d output/screencasts ]; then \
		echo -e "$(BLUE)[INFO]$(NC) Creating output directories..."; \
		mkdir -p output/screencasts output/screenshots logs; \
	fi
	@echo -e "$(GREEN)[SUCCESS]$(NC) Environment validation completed!"

check-deps: ## Check system dependencies
	$(call print_message,CHECK,$(CYAN),Checking system dependencies...)
	@command -v docker >/dev/null 2>&1 || { \
		$(call print_message,ERROR,$(RED),Docker is not installed); exit 1; }
	@docker compose version >/dev/null 2>&1 || { \
		$(call print_message,ERROR,$(RED),Docker Compose plugin is not available); exit 1; }
	@docker info >/dev/null 2>&1 || { \
		$(call print_message,ERROR,$(RED),Docker daemon is not running); exit 1; }
	$(call print_message,SUCCESS,$(GREEN),All dependencies are available!)

#==============================================================================
# BUILD COMMANDS
#==============================================================================

build: check-deps ## Build Docker images
	$(call print_message,BUILD,$(PURPLE),Building Docker images...)
	@$(DOCKER_COMPOSE) build --progress=plain
	$(call print_message,SUCCESS,$(GREEN),Build completed!)

rebuild: ## Rebuild Docker images without cache
	$(call print_message,BUILD,$(PURPLE),Rebuilding Docker images (no cache)...)
	@$(DOCKER_COMPOSE) build --no-cache --progress=plain
	$(call print_message,SUCCESS,$(GREEN),Rebuild completed!)

#==============================================================================
# CONTAINER MANAGEMENT
#==============================================================================

up: validate-env ## Start all services
	@echo "Starting Playwright Screencast environment..."
	@$(DOCKER_COMPOSE) up -d
	@sleep 5
	@$(MAKE) jupyter-url
	@echo "Environment is ready!"

down: ## Stop all services
	$(call print_message,STOP,$(YELLOW),Stopping all services...)
	@$(DOCKER_COMPOSE) down
	$(call print_message,SUCCESS,$(GREEN),Services stopped!)

restart: down up ## Restart all services

status: ## Show container status
	$(call print_message,STATUS,$(CYAN),Container Status:)
	@$(DOCKER_COMPOSE) ps
	@echo ""
	@$(DOCKER) system df

logs: ## Show real-time logs
	$(call print_message,LOGS,$(CYAN),Showing container logs (Ctrl+C to exit)...)
	@$(DOCKER_COMPOSE) logs -f --tail=100

shell: ## Open bash shell in main container
	$(call print_message,SHELL,$(CYAN),Opening shell in $(JUPYTER_SERVICE) container...)
	@$(DOCKER_COMPOSE) exec $(JUPYTER_SERVICE) bash

jupyter-shell: ## Open Jupyter-specific shell with environment
	$(call print_message,SHELL,$(CYAN),Opening Jupyter shell...)
	@$(DOCKER_COMPOSE) exec $(JUPYTER_SERVICE) bash -c "cd /app && exec bash"

#==============================================================================
# DEVELOPMENT ENVIRONMENT
#==============================================================================

dev: setup build up ## Start complete development environment
	$(call print_message,DEV,$(GREEN),Development environment started!)
	@$(MAKE) jupyter-url

prod: ## Start in production mode
	$(call print_message,PROD,$(PURPLE),Starting production environment...)
	@HEADLESS_MODE=true $(DOCKER_COMPOSE) up -d
	@$(MAKE) health

debug: ## Start with debug logging
	$(call print_message,DEBUG,$(YELLOW),Starting debug environment...)
	@LOG_LEVEL=DEBUG $(DOCKER_COMPOSE) up

quick-start: setup build up ## Complete quick start
	$(call print_message,QUICK,$(GREEN),Quick start completed successfully!)

#==============================================================================
# TESTING AND QUALITY
#==============================================================================

test: ## Run complete test suite
	$(call print_message,TEST,$(CYAN),Running test suite...)
	@$(DOCKER_COMPOSE) exec $(JUPYTER_SERVICE) $(PYTHON) -m pytest tests/ -v --tb=short

test-unit: ## Run unit tests only
	$(call print_message,TEST,$(CYAN),Running unit tests...)
	@$(DOCKER_COMPOSE) exec $(JUPYTER_SERVICE) $(PYTHON) -m pytest tests/test_recorder.py -v

test-integration: ## Run integration tests only  
	$(call print_message,TEST,$(CYAN),Running integration tests...)
	@$(DOCKER_COMPOSE) exec $(JUPYTER_SERVICE) $(PYTHON) -m pytest tests/test_integration.py -v -m "not slow"

test-coverage: ## Run tests with coverage report
	$(call print_message,TEST,$(CYAN),Running tests with coverage...)
	@$(DOCKER_COMPOSE) exec $(JUPYTER_SERVICE) $(PYTHON) -m pytest tests/ --cov=src --cov-report=html --cov-report=term

lint: ## Run code linting
	$(call print_message,LINT,$(CYAN),Running code linting...)
	@$(DOCKER_COMPOSE) exec $(JUPYTER_SERVICE) flake8 src/ tests/ --max-line-length=88
	@$(DOCKER_COMPOSE) exec $(JUPYTER_SERVICE) isort --check-only src/ tests/

format: ## Format code
	$(call print_message,FORMAT,$(CYAN),Formatting code...)
	@$(DOCKER_COMPOSE) exec $(JUPYTER_SERVICE) black src/ tests/
	@$(DOCKER_COMPOSE) exec $(JUPYTER_SERVICE) isort src/ tests/
	$(call print_message,SUCCESS,$(GREEN),Code formatting completed!)

type-check: ## Run type checking
	$(call print_message,TYPE,$(CYAN),Running type checking...)
	@$(DOCKER_COMPOSE) exec $(JUPYTER_SERVICE) mypy src/ --ignore-missing-imports

install-dev: ## Install development dependencies
	$(call print_message,INSTALL,$(CYAN),Installing development dependencies...)
	@$(DOCKER_COMPOSE) exec $(JUPYTER_SERVICE) pip install -r requirements-dev.txt

update-deps: ## Update dependencies
	$(call print_message,UPDATE,$(CYAN),Updating dependencies...)
	@$(DOCKER_COMPOSE) exec $(JUPYTER_SERVICE) pip install --upgrade -r requirements.txt

#==============================================================================
# DEMO COMMANDS
#==============================================================================

demo-youtube: ## Run YouTube trending demo
	$(call print_message,DEMO,$(YELLOW),Running YouTube trending demo...)
	@$(DOCKER_COMPOSE) exec $(JUPYTER_SERVICE) $(PYTHON) -c \
		"import asyncio; from src.screencast_recorder import demo_youtube_trending; asyncio.run(demo_youtube_trending())"
	$(call print_message,SUCCESS,$(GREEN),YouTube demo completed!)

demo-google: ## Run Google search demo
	$(call print_message,DEMO,$(YELLOW),Running Google search demo...)
	@$(DOCKER_COMPOSE) exec $(JUPYTER_SERVICE) $(PYTHON) -c \
		"import asyncio; from src.screencast_recorder import demo_google_search; asyncio.run(demo_google_search())"
	$(call print_message,SUCCESS,$(GREEN),Google demo completed!)

demo-ecommerce: ## Run e-commerce demo
	$(call print_message,DEMO,$(YELLOW),Running e-commerce demo...)
	@$(DOCKER_COMPOSE) exec $(JUPYTER_SERVICE) $(PYTHON) -c \
		"import asyncio; from src.screencast_recorder import demo_ecommerce; asyncio.run(demo_ecommerce())"
	$(call print_message,SUCCESS,$(GREEN),E-commerce demo completed!)

demo-all: demo-youtube demo-google demo-ecommerce ## Run all demos
	$(call print_message,SUCCESS,$(GREEN),All demos completed successfully!)

demo-custom: ## Run custom demo (requires DEMO_URL and DEMO_ACTIONS environment variables)
	$(call print_message,DEMO,$(YELLOW),Running custom demo...)
	@if [ -z "$(DEMO_URL)" ]; then \
		$(call print_message,ERROR,$(RED),DEMO_URL environment variable is required); \
		exit 1; \
	fi
	@$(DOCKER_COMPOSE) exec $(JUPYTER_SERVICE) $(PYTHON) scripts/run_custom_demo.py "$(DEMO_URL)" "$(DEMO_ACTIONS)"

#==============================================================================
# UTILITIES AND MAINTENANCE
#==============================================================================

jupyter-token: ## Show Jupyter access token
	@TOKEN=$(grep JUPYTER_TOKEN .env 2>/dev/null | cut -d'=' -f2 || echo 'docker-screencast-token'); \
	echo -e "$(CYAN)[TOKEN]$(NC) Jupyter Token: $TOKEN"

jupyter-url: jupyter-token ## Show Jupyter access URL
	@PORT=$(grep JUPYTER_PORT .env 2>/dev/null | cut -d'=' -f2 || echo '8888'); \
	TOKEN=$(grep JUPYTER_TOKEN .env 2>/dev/null | cut -d'=' -f2 || echo 'docker-screencast-token'); \
	echo -e "$(GREEN)[URL]$(NC) Jupyter Lab URL: http://localhost:$PORT?token=$TOKEN"

health: ## Check system health
	$(call print_message,HEALTH,$(CYAN),Checking system health...)
	@echo "Container Status:"
	@$(DOCKER_COMPOSE) ps
	@echo ""
	@echo "Jupyter Health:"
	@curl -s http://localhost:$(JUPYTER_PORT)/api/status 2>/dev/null || \
		$(call print_message,WARNING,$(YELLOW),Jupyter not accessible)
	@echo ""
	@echo "Disk Usage:"
	@$(DOCKER) system df
	@echo ""
	@echo "Recording Files:"
	@find output/screencasts -name "*.webm" -o -name "*.mp4" 2>/dev/null | wc -l | \
		xargs -I {} echo "Found {} video files"

backup: ## Backup recordings and important files
	$(call print_message,BACKUP,$(CYAN),Creating backup...)
	@BACKUP_NAME="screencast-backup-$$(date +%Y%m%d_%H%M%S)"; \
	tar -czf "$$BACKUP_NAME.tar.gz" \
		output/ logs/ notebooks/ .env 2>/dev/null || true; \
	$(call print_message,SUCCESS,$(GREEN),Backup created: $$BACKUP_NAME.tar.gz)

#==============================================================================
# CLEANUP COMMANDS
#==============================================================================

clean-videos: ## Remove old video recordings (older than 7 days)
	$(call print_message,CLEAN,$(YELLOW),Removing old video recordings...)
	@find output/screencasts -name "*.webm" -mtime +7 -delete 2>/dev/null || true
	@find output/screencasts -name "*.mp4" -mtime +7 -delete 2>/dev/null || true
	@find output/screenshots -name "*.png" -mtime +7 -delete 2>/dev/null || true
	$(call print_message,SUCCESS,$(GREEN),Old recordings cleaned!)

clean: ## Remove containers and networks
	$(call print_message,CLEAN,$(YELLOW),Removing containers and networks...)
	@$(DOCKER_COMPOSE) down --volumes --remove-orphans
	$(call print_message,SUCCESS,$(GREEN),Containers and networks cleaned!)

clean-images: ## Remove Docker images
	$(call print_message,CLEAN,$(YELLOW),Removing Docker images...)
	@$(DOCKER_COMPOSE) down --rmi local
	@$(DOCKER) image prune -f
	$(call print_message,SUCCESS,$(GREEN),Images cleaned!)

clean-all: clean clean-images clean-videos ## Complete cleanup
	$(call print_message,CLEAN,$(YELLOW),Performing complete cleanup...)
	@$(DOCKER) system prune -f --volumes
	@rm -rf logs/*.log 2>/dev/null || true
	$(call print_message,SUCCESS,$(GREEN),Complete cleanup finished!)

full-reset: clean-all setup build ## Nuclear option - complete reset
	$(call print_message,RESET,$(RED),Performing full reset...)
	$(call print_message,SUCCESS,$(GREEN),Full reset completed!)

#==============================================================================
# CI/CD AND AUTOMATION
#==============================================================================

ci: check-deps lint test build ## Run CI pipeline
	$(call print_message,CI,$(PURPLE),Running CI pipeline...)
	$(call print_message,SUCCESS,$(GREEN),CI pipeline completed successfully!)

#==============================================================================
# ADVANCED TARGETS
#==============================================================================

# Watch for file changes (requires entr)
watch-src: ## Watch source files for changes and run tests
	@if command -v entr >/dev/null 2>&1; then \
		find src tests -name "*.py" | entr -c make test-unit; \
	else \
		$(call print_message,ERROR,$(RED),entr is not installed. Install with: brew install entr); \
	fi

# Generate requirements file from current environment
freeze-deps: ## Generate requirements.txt from current environment
	$(call print_message,FREEZE,$(CYAN),Generating requirements.txt...)
	@$(DOCKER_COMPOSE) exec $(JUPYTER_SERVICE) pip freeze > requirements-frozen.txt
	$(call print_message,SUCCESS,$(GREEN),Requirements frozen to requirements-frozen.txt)

# Profile resource usage
profile: ## Show resource usage statistics
	$(call print_message,PROFILE,$(CYAN),Resource Usage Profile:)
	@$(DOCKER) stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"

# Security scan
security-scan: ## Run security scan on images
	$(call print_message,SECURITY,$(CYAN),Running security scan...)
	@if command -v trivy >/dev/null 2>&1; then \
		trivy image $(PROJECT_NAME)_$(JUPYTER_SERVICE); \
	else \
		$(call print_message,WARNING,$(YELLOW),trivy not installed - skipping security scan); \
	fi

#==============================================================================
# DOCUMENTATION TARGETS
#==============================================================================

docs: ## Generate documentation
	$(call print_message,DOCS,$(CYAN),Generating documentation...)
	@$(DOCKER_COMPOSE) exec $(JUPYTER_SERVICE) sphinx-build -b html docs/ docs/_build/

docs-serve: ## Serve documentation locally
	@$(DOCKER_COMPOSE) exec $(JUPYTER_SERVICE) python -m http.server 8080 --directory docs/_build/

#==============================================================================
# ENVIRONMENT INFO
#==============================================================================

info: ## Show environment information
	$(call print_message,INFO,$(CYAN),Environment Information:)
	@echo "Project: $(PROJECT_NAME)"
	@echo "Docker Compose: $$(docker compose version)"
	@echo "Docker: $$(docker --version)"
	@echo "Jupyter Port: $(JUPYTER_PORT)"
	@echo "Headless Mode: $(HEADLESS_MODE)"
	@echo "Log Level: $(LOG_LEVEL)"
	@echo ""
	@echo "Current Configuration:"
	@cat .env 2>/dev/null || echo "No .env file found"