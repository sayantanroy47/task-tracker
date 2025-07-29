#!/bin/bash
set -e

echo "============================================="
echo "Testing Flutter Build Process"
echo "============================================="

echo ""
echo "[STEP 1] Running flutter pub get..."
echo "============================================="
flutter pub get

echo ""
echo "[STEP 2] Running flutter pub deps..."
echo "============================================="
flutter pub deps

echo ""
echo "[STEP 3] Running flutter analyze..."
echo "============================================="
flutter analyze

echo ""
echo "[STEP 4] Running flutter build apk --debug..."
echo "============================================="
flutter build apk --debug

echo ""
echo "============================================="
echo "BUILD PROCESS COMPLETED SUCCESSFULLY!"
echo "============================================="
echo "All steps passed:"
echo "  ✓ Dependencies updated"
echo "  ✓ No dependency conflicts"
echo "  ✓ No code analysis issues"
echo "  ✓ APK build successful"
echo "============================================="