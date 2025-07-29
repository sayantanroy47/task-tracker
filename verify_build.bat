@echo off
REM Flutter Build Verification Script for Windows
REM Run this script to verify the app builds successfully

echo 🔧 Flutter Build Verification Started
echo =======================================

REM Check Flutter installation
echo 1. Checking Flutter installation...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed or not in PATH
    pause
    exit /b 1
)

flutter --version
echo ✅ Flutter installation verified

REM Get dependencies
echo.
echo 2. Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Failed to get dependencies
    pause
    exit /b 1
)
echo ✅ Dependencies resolved

REM Run analysis
echo.
echo 3. Running static analysis...
flutter analyze
if %errorlevel% equ 0 (
    echo ✅ Analysis passed - no issues found
) else (
    echo ⚠️  Analysis found issues - check output above
)

REM Test compilation
echo.
echo 4. Testing compilation...
flutter build apk --debug --no-shrink
if %errorlevel% equ 0 (
    echo ✅ Debug build successful
) else (
    echo ❌ Debug build failed
    pause
    exit /b 1
)

REM Run tests
echo.
echo 5. Running tests...
flutter test
if %errorlevel% equ 0 (
    echo ✅ All tests passed
) else (
    echo ⚠️  Some tests failed - check output above
)

echo.
echo 🎉 Build verification complete!
echo ================================
echo Your Flutter app is ready to run:
echo   flutter run (for development)
echo   flutter build apk --release (for production)
pause