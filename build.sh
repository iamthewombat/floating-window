#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/FloatingWindow" && pwd)"
APP_NAME="FloatingWindow"

echo "Building $APP_NAME (Release)..."
xcodebuild -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Release \
    build 2>&1 | tail -5

# Find the built app
BUILD_DIR=$(xcodebuild -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -showBuildSettings 2>/dev/null | grep " BUILT_PRODUCTS_DIR" | awk '{print $3}')

APP_PATH="$BUILD_DIR/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: Build product not found at $APP_PATH"
    exit 1
fi

# Kill running instance
pkill -x "$APP_NAME" 2>/dev/null || true
sleep 0.5

# Copy to Applications
echo "Installing to /Applications..."
rm -rf "/Applications/$APP_NAME.app"
cp -R "$APP_PATH" "/Applications/$APP_NAME.app"

echo "Launching $APP_NAME..."
open "/Applications/$APP_NAME.app"

echo "Done!"
