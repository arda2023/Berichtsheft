#!/bin/bash
set -e

# Remove any cached Flutter SDK directory
rm -rf flutter

# Clone Flutter SDK version 3.22.0
echo "Cloning Flutter SDK (3.22.0)..."
git clone https://github.com/flutter/flutter.git -b 3.22.0 --depth 1 flutter

# Add Flutter to PATH for the current session
export PATH="$PATH:$(pwd)/flutter/bin"

# Verify Flutter installation
flutter doctor

# Get dependencies
flutter pub get

# Build Flutter Web application using auto renderer
flutter build web --release --web-renderer auto \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
