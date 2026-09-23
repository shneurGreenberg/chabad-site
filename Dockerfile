# Amvera Flutter web build. Pin SDK 3.47.4 (matches Amvera guidance).
# Clone official Flutter tag (cirruslabs GHCR may lack 3.47.4).
# Do NOT download kaddish photos here ? that hung prior rebuilds.
# 2026-09-23: GitHub→Amvera rebuild so jewishsib-shneur serves main v=33 (PRs #33–#35).

FROM debian:bookworm-slim AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git unzip xz-utils zip ca-certificates libglu1-mesa \
 && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/flutter/flutter.git -b 3.47.4 --depth 1 /flutter
ENV PATH="/flutter/bin:${PATH}"
ENV PUB_CACHE=/root/.pub-cache

RUN flutter config --enable-web && flutter precache --web

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter --version && flutter pub get
COPY . .
RUN flutter build web --release --base-href / --no-tree-shake-icons --no-wasm-dry-run

RUN cp assets/images/community-emblem.png build/web/favicon.png \
 && cp assets/images/community-emblem.png build/web/icons/Icon-192.png \
 && cp assets/images/community-emblem.png build/web/icons/Icon-512.png \
 && cp assets/images/community-emblem.png build/web/icons/Icon-maskable-192.png \
 && cp assets/images/community-emblem.png build/web/icons/Icon-maskable-512.png \
 && mkdir -p build/web/kaddish-photos \
 && BUILD_ID="v31-$(date -u +%Y%m%dT%H%M%SZ)" \
 && echo "$BUILD_ID" > build/web/build-id.txt \
 && echo "<!-- $BUILD_ID -->" >> build/web/index.html \
 && cp build/web/index.html build/web/404.html \
 && echo "Build stamp: $BUILD_ID"

FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]


