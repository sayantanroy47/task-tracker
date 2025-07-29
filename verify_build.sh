#!/bin/bash

# Flutter Build Verification Script
# Run this script to verify the app builds successfully

set -e

echo "🔧 Flutter Build Verification Started"
echo "======================================="

# Check Flutter installation
echo "1. Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

flutter --version
echo "✅ Flutter installation verified"

# Get dependencies
echo ""
echo "2. Getting dependencies..."
flutter pub get
echo "✅ Dependencies resolved"

# Run analysis
echo ""
echo "3. Running static analysis..."
flutter analyze
if [ $? -eq 0 ]; then
    echo "✅ Analysis passed - no issues found"
else
    echo "⚠️  Analysis found issues - check output above"
fi

# Test compilation
echo ""
echo "4. Testing compilation..."
flutter build apk --debug --no-shrink
if [ $? -eq 0 ]; then
    echo "✅ Debug build successful"
else
    echo "❌ Debug build failed"
    exit 1
fi

# Run tests
echo ""
echo "5. Running tests..."
flutter test
if [ $? -eq 0 ]; then
    echo "✅ All tests passed"
else
    echo "⚠️  Some tests failed - check output above"
fi

echo ""
echo "🎉 Build verification complete!"
echo "================================"
echo "Your Flutter app is ready to run:"
echo "  flutter run (for development)"
echo "  flutter build apk --release (for production)"