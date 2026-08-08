#!/bin/bash
set -e

# Clone Flutter SDK if not already present
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK (stable)..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter
fi

# Add Flutter to PATH for the current session
export PATH="$PATH:$(pwd)/flutter/bin"

# Verify Flutter installation
flutter doctor

# Get dependencies
flutter pub get

# Build Flutter Web application
flutter build web --release --wasm \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
