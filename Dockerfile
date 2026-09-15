# Multi-stage Dockerfile for Flutter web on Amvera (fast path).
# Avoids cloning Flutter from git and downloading hundreds of kaddish photos
# during image build - those made Amvera builds hang while git tip advanced.

FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter config --enable-web && flutter pub get
COPY . .
RUN flutter build web --release --base-href / --no-tree-shake-icons --no-wasm-dry-run
RUN cp assets/images/community-emblem.png build/web/favicon.png \
 && cp assets/images/community-emblem.png build/web/icons/Icon-192.png \
 && cp assets/images/community-emblem.png build/web/icons/Icon-512.png \
 && cp assets/images/community-emblem.png build/web/icons/Icon-maskable-192.png \
 && cp assets/images/community-emblem.png build/web/icons/Icon-maskable-512.png \
 && mkdir -p build/web/kaddish-photos \
 && BUILD_ID="v29-$(date -u +%Y%m%dT%H%M%SZ)" \
 && echo "$BUILD_ID" > build/web/build-id.txt \
 && echo "<!-- $BUILD_ID -->" >> build/web/index.html \
 && cp build/web/index.html build/web/404.html \
 && echo "Build stamp: $BUILD_ID"

FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

