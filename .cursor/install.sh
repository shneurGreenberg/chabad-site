#!/usr/bin/env bash
# Idempotent bootstrap for the Chabad site Flutter web dev environment.
set -euo pipefail

FLUTTER_DIR="${FLUTTER_DIR:-$HOME/flutter}"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "Cloning Flutter stable SDK into $FLUTTER_DIR ..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
else
  echo "Flutter SDK already present at $FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter config --enable-web --no-analytics
flutter --version

cd "$(dirname "$0")/.."
flutter pub get
flutter precache --web

echo "Flutter web dev environment is ready."
