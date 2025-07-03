FROM python:3.11-slim

# Install system packages
RUN apt-get update || true && \
    apt-get install -y --no-install-recommends \
    xvfb fluxbox ffmpeg chromium chromium-driver \
    || apt-get install -y --fix-missing && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY scripts/ scripts/
COPY entrypoint.sh /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh

# ✅ Use bash explicitly to avoid exec format issues
ENTRYPOINT ["bash", "/app/entrypoint.sh"]
