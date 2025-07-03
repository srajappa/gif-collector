FROM browserless/chrome:arm64

USER root

# Install Python + pip using Debian's apt (not apk!)
RUN apt-get update && \
    apt-get install -y python3 python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

COPY scripts/ scripts/
COPY entrypoint.sh .
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["bash", "/app/entrypoint.sh"]
