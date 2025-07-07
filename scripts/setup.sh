#!/bin/bash

# Setup script for Playwright Screencast Environment
# This script helps initialize the development environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Main setup function
main() {
    print_info "Setting up Playwright Screencast Environment..."
    
    # Check prerequisites
    print_info "Checking prerequisites..."
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! docker compose version >/dev/null 2>&1; then
        print_error "Docker Compose plugin is not available. Please install Docker with Compose plugin."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
    
    # Create necessary directories
    print_info "Creating project directories..."
    
    directories=(
        "output/screencasts"
        "output/screenshots" 
        "logs"
        "notebooks/examples"
        "src/examples"
        "tests"
        "config"
    )
    
    for dir in "${directories[@]}"; do
        mkdir -p "$dir"
        print_info "Created directory: $dir"
    done
    
    # Create .gitkeep files for empty directories
    touch output/screencasts/.gitkeep
    touch output/screenshots/.gitkeep
    touch logs/.gitkeep
    
    # Setup environment file
    if [ ! -f .env ]; then
        print_info "Creating .env file from template..."
        cp .env.example .env
        print_warning "Please edit .env file with your preferred settings"
    else
        print_info ".env file already exists"
    fi
    
    # Set proper permissions
    print_info "Setting directory permissions..."
    chmod 755 output/screencasts
    chmod 755 output/screenshots
    chmod 755 logs
    
    # Make scripts executable
    print_info "Making scripts executable..."
    chmod +x scripts/*.sh
    
    # Build Docker image
    print_info "Building Docker image..."
    if docker compose build; then
        print_success "Docker image built successfully"
    else
        print_error "Failed to build Docker image"
        exit 1
    fi
    
    # Create example notebooks if they don't exist
    create_example_notebooks
    
    print_success "Setup completed successfully!"
    print_info ""
    print_info "Next steps:"
    print_info "1. Edit .env file if needed"
    print_info "2. Run: docker-compose up"
    print_info "3. Open http://localhost:8888 in your browser"
    print_info "4. Use token from .env file or check docker logs"
}

# Function to create example notebooks
create_example_notebooks() {
    print_info "Creating example notebooks..."
    
    # Main screencast recorder notebook
    cat > notebooks/screencast_recorder.ipynb << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Playwright Screencast Recorder\n",
    "\n",
    "This notebook demonstrates how to create automated screencasts using Playwright."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Import the screencast recorder\n",
    "import sys\n",
    "sys.path.append('/app')\n",
    "\n",
    "from src.screencast_recorder import (\n",
    "    ScreencastRecorder,\n",
    "    YouTubeScreencast,\n",
    "    WebsiteActionRecorder,\n",
    "    EcommerceScreencast\n",
    ")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Example: YouTube Trending Screencast\n",
    "async def youtube_demo():\n",
    "    recorder = YouTubeScreencast()\n",
    "    try:\n",
    "        await recorder.setup_browser(headless=False, recording_name=\"youtube_demo\")\n",
    "        await recorder.visit_trending_section()\n",
    "    finally:\n",
    "        await recorder.cleanup()\n",
    "\n",
    "# Run the demo\n",
    "await youtube_demo()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Example: Custom Website Actions\n",
    "actions = [\n",
    "    {'action': 'wait', 'duration': 2000},\n",
    "    {'action': 'click', 'selector': 'input[name=\"q\"]'},\n",
    "    {'action': 'type', 'selector': 'input[name=\"q\"]', 'text': 'playwright automation'},\n",
    "    {'action': 'wait', 'duration': 1000},\n",
    "    {'action': 'scroll', 'pixels': 300}\n",
    "]\n",
    "\n",
    "async def custom_demo():\n",
    "    recorder = WebsiteActionRecorder()\n",
    "    try:\n",
    "        await recorder.setup_browser(headless=False, recording_name=\"custom_demo\")\n",
    "        await recorder.record_custom_action('https://www.google.com', actions)\n",
    "    finally:\n",
    "        await recorder.cleanup()\n",
    "\n",
    "# Run the demo\n",
    "await custom_demo()"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.9.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

    print_success "Created notebooks/screencast_recorder.ipynb"
}

# Run setup if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi