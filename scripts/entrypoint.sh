#!/bin/bash

# Entrypoint script for Playwright Screencast Docker container

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Playwright Screencast Environment...${NC}"

# Function to log messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root (shouldn't be, but handle gracefully)
if [ "$EUID" -eq 0 ]; then
    log_warn "Running as root. This is not recommended for security reasons."
fi

# Start virtual display for headless browser testing
log_info "Starting virtual display..."
Xvfb :99 -screen 0 1920x1080x24 &
export DISPLAY=:99

# Wait for display to be ready
sleep 2

# Verify Playwright installation
log_info "Verifying Playwright installation..."
if ! python3 -c "import playwright; print('Playwright OK')" 2>/dev/null; then
    log_error "Playwright not properly installed"
    exit 1
fi

# Verify browsers are installed
log_info "Checking Playwright browsers..."
if ! playwright --version 2>/dev/null; then
    log_warn "Playwright CLI not found, installing browsers..."
    playwright install chromium
fi

# Create necessary directories
log_info "Setting up directories..."
mkdir -p /app/output/screencasts
mkdir -p /app/logs
mkdir -p /home/jupyter/.jupyter

# Set proper permissions
chmod 755 /app/output/screencasts
chmod 755 /app/logs

# Generate Jupyter configuration if not exists
if [ ! -f /home/jupyter/.jupyter/jupyter_lab_config.py ]; then
    log_info "Generating Jupyter configuration..."
    cat > /home/jupyter/.jupyter/jupyter_lab_config.py << 'EOF'
import os

# Basic configuration
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
c.ServerApp.allow_root = True

# Security settings
c.ServerApp.token = os.environ.get('JUPYTER_TOKEN', 'docker-screencast-token')
c.ServerApp.allow_origin = '*'
c.ServerApp.disable_check_xsrf = True

# Enable JupyterLab
c.LabApp.default_url = '/lab'

# Set notebook directory
c.ServerApp.notebook_dir = '/app/notebooks'

# Logging
c.ServerApp.log_level = 'INFO'
c.ServerApp.log_file = '/app/logs/jupyter.log'
EOF
fi

# Set up Python path
export PYTHONPATH=/app:$PYTHONPATH

# Log environment info
log_info "Environment setup:"
echo "  - Python version: $(python3 --version)"
echo "  - Playwright version: $(python3 -c 'import playwright; print(playwright.__version__)')"
echo "  - Working directory: $(pwd)"
echo "  - Display: $DISPLAY"
echo "  - Jupyter token: ${JUPYTER_TOKEN:-docker-screencast-token}"

# Health check function
health_check() {
    local retries=0
    local max_retries=30
    
    while [ $retries -lt $max_retries ]; do
        if curl -f http://localhost:8888/api 2>/dev/null; then
            log_info "Jupyter is healthy"
            return 0
        fi
        
        retries=$((retries + 1))
        log_info "Waiting for Jupyter to start... (attempt $retries/$max_retries)"
        sleep 2
    done
    
    log_error "Jupyter failed to start within expected time"
    return 1
}

# Function to handle shutdown gracefully
shutdown_handler() {
    log_info "Shutting down gracefully..."
    
    # Kill Xvfb
    pkill -f "Xvfb :99" || true
    
    # Kill any remaining browser processes
    pkill -f "chromium" || true
    pkill -f "playwright" || true
    
    log_info "Shutdown complete"
    exit 0
}

# Set up signal handlers
trap shutdown_handler SIGTERM SIGINT

# Start Jupyter in background for health check
log_info "Starting Jupyter Lab..."
if [ "$#" -eq 0 ]; then
    # Default command
    jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root &
    JUPYTER_PID=$!
else
    # Custom command
    "$@" &
    JUPYTER_PID=$!
fi

# Wait a bit and then run health check
sleep 5
if health_check; then
    log_info "Jupyter Lab started successfully!"
    echo -e "${GREEN}Access your environment at: http://localhost:8888${NC}"
    echo -e "${GREEN}Token: ${JUPYTER_TOKEN:-docker-screencast-token}${NC}"
else
    log_error "Failed to start Jupyter Lab"
    exit 1
fi

# Keep the container running
wait $JUPYTER_PID