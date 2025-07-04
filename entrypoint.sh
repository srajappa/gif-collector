#!/bin/bash
set -e

echo "Starting Xvfb..."
Xvfb :99 -screen 0 1280x720x24 &

export DISPLAY=:99

echo "Starting window manager..."
fluxbox &

echo "Running automation script..."
python3 /app/scripts/record_webapp.py

echo "Done."
