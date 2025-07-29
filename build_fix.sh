#!/bin/bash

echo "Starting Flutter build fix process..."

# Clean previous builds
echo "Cleaning Flutter project..."
flutter clean

# Get dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# Run analysis to check for issues
echo "Analyzing Flutter code..."
flutter analyze

# Build APK
echo "Building APK..."
flutter build apk --debug

echo "Build process completed!"