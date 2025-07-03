FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:99

# 1. Install dependencies
# RUN apt-get update && apt-get install -y \
#     wget unzip curl gnupg \
#     python3 python3-pip \
#     xvfb fluxbox ffmpeg \
#     fonts-liberation libappindicator3-1 libasound2 libatk-bridge2.0-0 \
#     libatk1.0-0 libcups2 libdbus-1-3 libgdk-pixbuf2.0-0 \
#     libnspr4 libnss3 libx11-xcb1 libxcomposite1 libxdamage1 libxrandr2 \
#     xdg-utils ca-certificates \
#     && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN apt-get update || true && \
    apt-get install -y --no-install-recommends \
    wget unzip curl gnupg python3 python3-pip xvfb fluxbox ffmpeg \
    fonts-liberation libappindicator3-1 libasound2 libatk-bridge2.0-0 \
    libatk1.0-0 libcups2 libdbus-1-3 libgdk-pixbuf2.0-0 \
    libnspr4 libnss3 libx11-xcb1 libxcomposite1 libxdamage1 libxrandr2 \
    xdg-utils ca-certificates \
    || apt-get install -y --fix-missing && \
    apt-get clean && rm -rf /var/lib/apt/lists/*


# Step 1: Base + curl/gpg first
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl gnupg ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Step 2: Add Chrome repo
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | \
    gpg --dearmor -o /usr/share/keyrings/google.gpg && \
    echo "deb [arch=arm64 signed-by=/usr/share/keyrings/google.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list && \
    apt-get update && \
    apt-get install -y google-chrome-stable && \
    apt-get clean && rm -rf /var/lib/apt/lists/*


# 2. Install Chrome
# RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google.gpg && \
#     echo "deb [arch=arm64 signed-by=/usr/share/keyrings/google.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list && \
#     apt-get update && \
#     apt-get install -y google-chrome-stable

# 3. Install ChromeDriver (matching version)
RUN CHROME_VERSION=$(google-chrome --version | awk '{print $3}' | cut -d '.' -f 1) && \
    DRIVER_URL="https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/${CHROME_VERSION}.0.0.0/linux64/chromedriver-linux64.zip" && \
    wget -O /tmp/chromedriver.zip $DRIVER_URL && \
    unzip /tmp/chromedriver.zip -d /usr/local/bin && \
    mv /usr/local/bin/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver && \
    chmod +x /usr/local/bin/chromedriver && \
    rm -rf /tmp/chromedriver.zip /usr/local/bin/chromedriver-linux64

# 4. Set up Python code
WORKDIR /app
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

COPY scripts/ scripts/
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# 5. Set entrypoint using bash
ENTRYPOINT ["bash", "/app/entrypoint.sh"]
