# Dockerfile for Playwright Screencast Environment
# Using standard Python image with Playwright

# FROM --platform=linux/amd64 python:3.11-slim
# Dockerfile for Playwright Screencast Environment
# Using official Playwright image

FROM  mcr.microsoft.com/playwright/python:v1.40.0-jammy

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app
ENV DISPLAY=:99

# Set working directory
WORKDIR /app

# Install Jupyter and additional Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Create necessary directories
RUN mkdir -p /app/output/screencasts \
    /app/output/screenshots \
    /app/logs \
    /app/notebooks \
    /app/src \
    /app/tests \
    /app/config \
    /app/scripts

# Copy application files
COPY src/ ./src/
COPY notebooks/ ./notebooks/
COPY config/ ./config/
COPY scripts/ ./scripts/
COPY tests/ ./tests/

# Copy and set up entrypoint
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create non-root user (if not exists) and set permissions
RUN if ! id "jupyter" &>/dev/null; then \
    groupadd -r jupyter && \
    useradd -r -g jupyter -d /home/jupyter -s /bin/bash jupyter && \
    mkdir -p /home/jupyter && \
    chown -R jupyter:jupyter /home/jupyter; \
    fi

# Set proper permissions
RUN chown -R jupyter:jupyter /app

# Switch to non-root user
USER jupyter

# Expose Jupyter port
EXPOSE 8888

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8888/api || exit 1

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Default command
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]