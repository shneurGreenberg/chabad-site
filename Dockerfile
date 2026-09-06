# Multi-stage Dockerfile for Flutter web deployment on Amvera
# Version 1 - Custom domain www.jewishsib.com

# Stage 1: Build Flutter web application
FROM debian:bookworm-slim AS build

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    ca-certificates \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Clone Flutter SDK
ARG FLUTTER_VERSION=3.24.5
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git /flutter

# Add Flutter to PATH
ENV PATH="/flutter/bin:${PATH}"

# Pre-download Flutter artifacts
RUN flutter doctor -v && \
    flutter config --enable-web && \
    flutter precache --web

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy entire project
COPY . .

# Build Flutter web with root base-href for custom domain
RUN flutter build web --release --base-href / --no-tree-shake-icons --no-wasm-dry-run

# Download kaddish cemetery photos (same as GitHub Pages workflow)
RUN mkdir -p build/web/kaddish-photos && \
    curl -fsSL https://synagogue-kadish-shneur.amvera.io/s/novosibirsk/api/board -o /tmp/board.json && \
    echo "Downloading cemetery photos..." && \
    cat /tmp/board.json | jq -r '.people[] | select(.photo != null and .photo != "") | .photo' | while read -r filename; do \
      if [ ! -z "$filename" ]; then \
        url="https://synagogue-kadish-shneur.amvera.io/photos/${filename}?w=280"; \
        echo "Downloading: $url"; \
        curl -fsSL -o "build/web/kaddish-photos/${filename}" "$url" --max-time 10 || echo "Failed to download $filename, skipping"; \
      fi; \
    done && \
    PHOTO_COUNT=$(ls -1 build/web/kaddish-photos 2>/dev/null | wc -l) && \
    echo "Downloaded $PHOTO_COUNT photos" && \
    if [ "$PHOTO_COUNT" -eq 0 ]; then \
      echo "ERROR: No photos downloaded. Failing to prevent empty deployment."; \
      exit 1; \
    fi

# Create SPA fallback (404.html)
RUN cp build/web/index.html build/web/404.html

# Stage 2: Serve with nginx
FROM nginx:alpine

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built Flutter web app from build stage
COPY --from=build /app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
