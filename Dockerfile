FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN rm -rf /var/lib/apt/lists/*
# Install system dependencies
RUN apt-get update --fix-missing

RUN apt-get --allow-unauthenticated --no-install-recommends install -y python3 python3-pip
# RUN apt-get install -y wget unzip curl gnupg2
# RUN apt-get install -y ffmpeg xvfb fluxbox 
# RUN apt-get install -y libglib2.0-0 libnss3 libx11-xcb1 libxcomposite1
# RUN apt-get install -y libxcursor1 libxdamage1 libxrandr2 libasound2 libatk1.0-0
# RUN apt-get install -y libatk-bridge2.0-0 libcups2 libdbus-1-3 libgdk-pixbuf2.0-0 
# RUN apt-get install -y libxss1 libxshmfence1 xdg-utils fonts-liberation
# RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# # Install Chrome
# RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google.gpg \
#     && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
#     && apt-get update && apt-get install -y google-chrome-stable \
#     && apt-get clean && rm -rf /var/lib/apt/lists/*

# # Install ChromeDriver
# RUN pip3 install webdriver-manager selenium

# # Set up app
# WORKDIR /app
# COPY . /app
# RUN chmod +x /app/entrypoint.sh

# ENTRYPOINT ["/app/entrypoint.sh"]
