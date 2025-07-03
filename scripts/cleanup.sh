#!/bin/bash

# Cleanup script for Web Interaction GIF Generator
echo "🧹 Cleaning up Web Interaction GIF Generator..."

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

# Detect Docker Compose command
if command -v docker &> /dev/null && docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
    print_status "Using Docker Compose V2"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
    print_status "Using Docker Compose (legacy)"
else
    print_error "Docker Compose not found"
    exit 1
fi

# Function to clean Docker resources
cleanup_docker() {
    print_status "Stopping and removing containers..."
    
    if $DOCKER_COMPOSE_CMD down --remove-orphans; then
        print_success "Containers stopped and removed"
    else
        print_warning "Failed to stop some containers"
    fi
    
    print_status "Removing Docker images..."
    if $DOCKER_COMPOSE_CMD down --rmi all --volumes; then
        print_success "Images and volumes removed"
    else
        print_warning "Some images or volumes may still exist"
    fi
}

# Function to clean output files
cleanup_output() {
    print_status "Cleaning output directory..."
    
    if [ -d "output/videos" ]; then
        rm -f output/videos/*.webm output/videos/*.mp4
        print_success "Video files cleaned"
    fi
    
    if [ -d "output/gifs" ]; then
        rm -f output/gifs/*.gif
        print_success "GIF files cleaned"
    fi
    
    if [ -d "logs" ]; then
        rm -f logs/*.log
        print_success "Log files cleaned"
    fi
}

# Function to clean node modules
cleanup_node() {
    print_status "Cleaning Node.js dependencies..."
    
    if [ -d "node_modules" ]; then
        rm -rf node_modules
        print_success "Node modules removed"
    fi
    
    if [ -d "test-app/node_modules" ]; then
        rm -rf test-app/node_modules
        print_success "Test app node modules removed"
    fi
    
    if [ -f "package-lock.json" ]; then
        rm -f package-lock.json
        print_success "Package lock file removed"
    fi
}

# Function to clean temporary files
cleanup_temp() {
    print_status "Cleaning temporary files..."
    
    find . -name "*.tmp" -delete 2>/dev/null || true
    find . -name "*.temp" -delete 2>/dev/null || true
    find . -name ".DS_Store" -delete 2>/dev/null || true
    
    print_success "Temporary files cleaned"
}

# Main cleanup function
main() {
    echo "🧹 Web Interaction GIF Generator Cleanup"
    echo "========================================"
    echo ""
    
    # Parse command line arguments
    CLEAN_DOCKER=false
    CLEAN_OUTPUT=false
    CLEAN_NODE=false
    CLEAN_TEMP=false
    CLEAN_ALL=false
    
    for arg in "$@"; do
        case $arg in
            --docker)
                CLEAN_DOCKER=true
                ;;
            --output)
                CLEAN_OUTPUT=true
                ;;
            --node)
                CLEAN_NODE=true
                ;;
            --temp)
                CLEAN_TEMP=true
                ;;
            --all)
                CLEAN_ALL=true
                ;;
            --help|-h)
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  --docker    Clean Docker containers, images, and volumes"
                echo "  --output    Clean generated videos and GIFs"
                echo "  --node      Clean Node.js dependencies"
                echo "  --temp      Clean temporary files"
                echo "  --all       Clean everything"
                echo "  --help      Show this help message"
                echo ""
                exit 0
                ;;
            *)
                print_warning "Unknown option: $arg"
                ;;
        esac
    done
    
    # If no specific options, clean everything
    if [ "$CLEAN_ALL" = true ] || [ $# -eq 0 ]; then
        CLEAN_DOCKER=true
        CLEAN_OUTPUT=true
        CLEAN_NODE=true
        CLEAN_TEMP=true
    fi
    
    # Perform cleanup operations
    if [ "$CLEAN_DOCKER" = true ]; then
        cleanup_docker
    fi
    
    if [ "$CLEAN_OUTPUT" = true ]; then
        cleanup_output
    fi
    
    if [ "$CLEAN_NODE" = true ]; then
        cleanup_node
    fi
    
    if [ "$CLEAN_TEMP" = true ]; then
        cleanup_temp
    fi
    
    echo ""
    print_success "Cleanup completed!"
    echo ""
    echo "To rebuild and restart:"
    echo "1. Run: ./scripts/setup.sh"
    echo "2. Or manually: $DOCKER_COMPOSE_CMD up -d"
    echo ""
}

# Run main function
main "$@"