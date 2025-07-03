#!/bin/bash

# Web Interaction GIF Generator Setup Script
echo "🚀 Setting up Web Interaction GIF Generator..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
check_docker() {
    print_status "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check for Docker Compose (try both V2 and legacy)
    if command -v docker &> /dev/null && docker compose version &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker compose"
        print_success "Docker and Docker Compose V2 are installed"
    elif command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker-compose"
        print_success "Docker and Docker Compose (legacy) are installed"
    else
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
}

# Check if Node.js is installed (for local development)
check_node() {
    print_status "Checking Node.js installation..."
    if ! command -v node &> /dev/null; then
        print_warning "Node.js is not installed. This is only needed for local development."
    else
        NODE_VERSION=$(node --version)
        print_success "Node.js ${NODE_VERSION} is installed"
    fi
}

# Create necessary directories
create_directories() {
    print_status "Creating project directories..."
    
    mkdir -p output/videos
    mkdir -p output/gifs
    mkdir -p logs
    
    print_success "Directories created"
}

# Set up environment file
setup_env() {
    print_status "Setting up environment configuration..."
    
    if [ ! -f .env ]; then
        cat > .env << EOF
# Environment Configuration
NODE_ENV=development

# Browser Settings
HEADLESS=true
VIEWPORT_WIDTH=1280
VIEWPORT_HEIGHT=720

# Recording Settings
OUTPUT_DIR=/app/output
STEP_DELAY=1500

# Test App Settings
TEST_APP_URL=http://test-app:3001

# Performance Settings
MAX_CONCURRENT_RECORDINGS=3
REQUEST_TIMEOUT=300000

# File Management
MAX_FILE_SIZE=104857600
AUTO_CLEANUP=false
MAX_FILE_AGE=604800000

# Logging
LOG_LEVEL=info
EOF
        print_success "Environment file created (.env)"
    else
        print_warning "Environment file already exists (.env)"
    fi
}

# Set up Git ignore
setup_gitignore() {
    print_status "Setting up .gitignore..."
    
    if [ ! -f .gitignore ]; then
        cat > .gitignore << EOF
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Output files
output/videos/*
output/gifs/*
!output/videos/.gitkeep
!output/gifs/.gitkeep

# Logs
logs/
*.log

# Docker
.docker/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Temporary files
tmp/
temp/
*.tmp

# Coverage
coverage/

# Build artifacts
dist/
build/
EOF
        print_success ".gitignore created"
    else
        print_warning ".gitignore already exists"
    fi
}

# Create .gitkeep files for empty directories
create_gitkeep() {
    print_status "Creating .gitkeep files..."
    
    touch output/videos/.gitkeep
    touch output/gifs/.gitkeep
    touch logs/.gitkeep
    
    print_success ".gitkeep files created"
}

# Download and build Docker images
build_docker() {
    print_status "Building Docker images..."
    
    if $DOCKER_COMPOSE_CMD build; then
        print_success "Docker images built successfully"
    else
        print_error "Failed to build Docker images"
        exit 1
    fi
}

# Verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    # Check if docker-compose.yml exists
    if [ ! -f docker-compose.yml ]; then
        print_error "docker-compose.yml not found"
        exit 1
    fi
    
    # Check if main application files exist
    if [ ! -f src/index.js ]; then
        print_error "Main application file (src/index.js) not found"
        exit 1
    fi
    
    # Check if test app files exist
    if [ ! -f test-app/server.js ]; then
        print_error "Test application file (test-app/server.js) not found"
        exit 1
    fi
    
    print_success "All required files are present"
}

# Start services
start_services() {
    print_status "Starting services..."
    
    if $DOCKER_COMPOSE_CMD up -d; then
        print_success "Services started successfully"
        
        # Wait a bit for services to initialize
        sleep 5
        
        # Check service health
        print_status "Checking service health..."
        
        # Check if containers are running
        if $DOCKER_COMPOSE_CMD ps | grep -q "Up"; then
            print_success "Containers are running"
            
            # Display service URLs
            echo ""
            echo "🎉 Setup completed successfully!"
            echo ""
            echo "Service URLs:"
            echo "📱 GIF Generator Interface: http://localhost:3000"
            echo "🎯 Test Application: http://localhost:3001"
            echo "🔍 Health Check: http://localhost:3000/health"
            echo ""
            echo "Useful commands:"
            echo "📊 View logs: $DOCKER_COMPOSE_CMD logs -f"
            echo "⏹️ Stop services: $DOCKER_COMPOSE_CMD down"
            echo "🔄 Restart services: $DOCKER_COMPOSE_CMD restart"
            echo "🧹 Clean up: ./scripts/cleanup.sh"
            echo ""
        else
            print_warning "Some containers may not be running properly"
            print_status "Check logs with: $DOCKER_COMPOSE_CMD logs"
        fi
    else
        print_error "Failed to start services"
        exit 1
    fi
}

# Main setup function
main() {
    echo "🎬 Web Interaction GIF Generator Setup"
    echo "======================================"
    echo ""
    
    check_docker
    check_node
    create_directories
    setup_env
    setup_gitignore
    create_gitkeep
    verify_installation
    build_docker
    start_services
    
    echo ""
    print_success "Setup process completed!"
    echo ""
    echo "Next steps:"
    echo "1. Visit http://localhost:3000 to access the GIF Generator"
    echo "2. Visit http://localhost:3001 to see the test application"
    echo "3. Check the documentation in the docs/ folder"
    echo "4. Run sample flows with: npm run run-flows"
    echo ""
}

# Run main function
main "$@"