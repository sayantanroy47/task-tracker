@echo off
setlocal enabledelayedexpansion

:: Task Tracker - Windows Quick Start Script
:: This script helps you quickly set up and run the Flutter Task Tracker app on Windows

echo.
echo ========================================
echo    Task Tracker - Windows Quick Start
echo ========================================
echo.

:: Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed or not in PATH
    echo.
    echo Please install Flutter first:
    echo 1. Download from: https://docs.flutter.dev/get-started/install/windows
    echo 2. Extract to C:\flutter
    echo 3. Add C:\flutter\bin to your PATH
    echo 4. Run 'flutter doctor' to verify installation
    echo.
    pause
    exit /b 1
)

echo ✅ Flutter detected!
echo.

:: Display menu
:menu
echo ========================================
echo        Choose an option:
echo ========================================
echo 1. 🚀 Quick Start (Web Browser - Recommended)
echo 2. 🖥️  Run on Windows Desktop
echo 3. 📱 Run on Android Device/Emulator
echo 4. 🔧 Install Dependencies Only
echo 5. 🧪 Run Tests
echo 6. 🔍 Analyze Code
echo 7. 📊 Full Verification (Build + Test)
echo 8. ❓ Help & Troubleshooting
echo 9. 🚪 Exit
echo.
set /p choice="Enter your choice (1-9): "

if "%choice%"=="1" goto web_start
if "%choice%"=="2" goto windows_start
if "%choice%"=="3" goto android_start
if "%choice%"=="4" goto install_deps
if "%choice%"=="5" goto run_tests
if "%choice%"=="6" goto analyze
if "%choice%"=="7" goto full_verification
if "%choice%"=="8" goto help
if "%choice%"=="9" goto exit
echo Invalid choice. Please try again.
goto menu

:web_start
echo.
echo ========================================
echo    🚀 Starting Task Tracker on Web
echo ========================================
echo Installing dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Failed to get dependencies
    pause
    goto menu
)

echo.
echo Starting web server...
echo 📱 Your app will open at: http://localhost:58080
echo 🛑 Press Ctrl+C to stop the server
echo.
flutter run -d chrome --web-port=58080
goto menu

:windows_start
echo.
echo ========================================
echo   🖥️  Starting Task Tracker on Windows
echo ========================================

:: Check if Windows is enabled
flutter config --enable-windows-desktop >nul 2>&1

echo Installing dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Failed to get dependencies
    pause
    goto menu
)

echo.
echo Starting Windows desktop app...
flutter run -d windows
goto menu

:android_start
echo.
echo ========================================
echo   📱 Starting Task Tracker on Android
echo ========================================

echo Checking for Android devices...
flutter devices

echo.
echo Installing dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Failed to get dependencies
    pause
    goto menu
)

echo.
echo Starting on Android device/emulator...
echo 💡 Make sure you have an Android device connected or emulator running
flutter run
goto menu

:install_deps
echo.
echo ========================================
echo      🔧 Installing Dependencies
echo ========================================
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Failed to install dependencies
    pause
    goto menu
)
echo ✅ Dependencies installed successfully!
echo.
pause
goto menu

:run_tests
echo.
echo ========================================
echo         🧪 Running Tests
echo ========================================
echo Installing dependencies...
flutter pub get

echo.
echo Running all tests...
flutter test
if %errorlevel% equ 0 (
    echo ✅ All tests passed!
) else (
    echo ⚠️  Some tests failed - check output above
)
echo.
pause
goto menu

:analyze
echo.
echo ========================================
echo        🔍 Analyzing Code
echo ========================================
echo Installing dependencies...
flutter pub get

echo.
echo Running static analysis...
flutter analyze
if %errorlevel% equ 0 (
    echo ✅ Analysis passed - no issues found!
) else (
    echo ⚠️  Analysis found issues - check output above
)
echo.
pause
goto menu

:full_verification
echo.
echo ========================================
echo      📊 Full Build Verification
echo ========================================
echo This will run a complete verification of the app...
echo.

echo 1️⃣ Installing dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Failed to get dependencies
    goto verification_failed
)

echo.
echo 2️⃣ Running code analysis...
flutter analyze
if %errorlevel% neq 0 (
    echo ❌ Code analysis failed
    goto verification_failed
)

echo.
echo 3️⃣ Running tests...
flutter test
if %errorlevel% neq 0 (
    echo ❌ Tests failed
    goto verification_failed
)

echo.
echo 4️⃣ Testing debug build...
flutter build apk --debug
if %errorlevel% neq 0 (
    echo ❌ Debug build failed
    goto verification_failed
)

echo.
echo 🎉 ========================================
echo     Full Verification SUCCESSFUL!
echo ========================================
echo ✅ Dependencies installed
echo ✅ Code analysis passed
echo ✅ All tests passed
echo ✅ Debug build successful
echo.
echo Your Task Tracker app is ready to run!
echo.
pause
goto menu

:verification_failed
echo.
echo ❌ ========================================
echo     Verification FAILED
echo ========================================
echo Please check the errors above and fix them.
echo You can also try individual steps from the main menu.
echo.
pause
goto menu

:help
echo.
echo ========================================
echo      ❓ Help & Troubleshooting
echo ========================================
echo.
echo 🔧 COMMON ISSUES:
echo.
echo 1. "Flutter not found"
echo    - Install Flutter from: https://docs.flutter.dev/get-started/install/windows
echo    - Add Flutter to your PATH environment variable
echo    - Restart command prompt after installation
echo.
echo 2. "No connected devices"
echo    - For web: Use option 1 (runs in Chrome browser)
echo    - For Windows: Use option 2 (desktop app)
echo    - For Android: Connect device or start Android emulator
echo.
echo 3. "Build failed"
echo    - Run "flutter doctor" to check setup
echo    - Try "flutter clean" then "flutter pub get"
echo    - Check that you have the latest Flutter version
echo.
echo 4. "Dependency issues"
echo    - Make sure you have internet connection
echo    - Try deleting pubspec.lock and running "flutter pub get"
echo.
echo 📱 ABOUT TASK TRACKER:
echo This is a cross-platform voice-powered task management app with:
echo • Voice-to-text task creation with natural language processing
echo • Calendar integration with task scheduling
echo • Smart notifications and reminders
echo • Chat integration for extracting tasks from messages
echo • Search and filtering capabilities
echo • Offline-first design with local SQLite storage
echo.
echo 🆘 Need more help?
echo • Check README.md in the project folder
echo • Visit: https://docs.flutter.dev/
echo • GitHub Issues: Report bugs and get support
echo.
pause
goto menu

:exit
echo.
echo Thanks for using Task Tracker! 👋
echo.
echo 💡 Quick tip: You can run this script anytime to start the app
echo    Just double-click quick_start.bat in Windows Explorer
echo.
pause
exit /b 0

:: End of script