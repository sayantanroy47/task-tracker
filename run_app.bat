@echo off
echo ========================================
echo    Task Tracker - Flutter App Runner
echo ========================================
echo.

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Flutter is not installed or not in PATH
    echo.
    echo Please install Flutter from: https://flutter.dev/docs/get-started/install
    echo Or use the web version option below.
    goto :web_option
)

echo Flutter detected! Checking available devices...
echo.

REM List available devices
flutter devices

echo.
echo ========================================
echo         Choose Running Option:
echo ========================================
echo 1. Run on Chrome/Web Browser (Recommended)
echo 2. Run on Windows Desktop
echo 3. Run simple version on Web
echo 4. Just analyze code (no running)
echo 5. Install dependencies only
echo 6. Exit
echo.
set /p choice="Enter your choice (1-6): "

if "%choice%"=="1" goto :web
if "%choice%"=="2" goto :windows
if "%choice%"=="3" goto :simple_web
if "%choice%"=="4" goto :analyze
if "%choice%"=="5" goto :deps
if "%choice%"=="6" goto :exit

:web
echo.
echo ========================================
echo     Running on Web Browser (Chrome)
echo ========================================
echo Installing dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to get dependencies
    pause
    exit /b 1
)

echo.
echo Starting web server...
echo Your app will open in Chrome browser at http://localhost:58080
echo Press Ctrl+C to stop the server
echo.
call flutter run -d chrome --web-port=58080
goto :end

:windows
echo.
echo ========================================
echo       Running on Windows Desktop
echo ========================================
echo Installing dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to get dependencies
    pause
    exit /b 1
)

echo.
echo Starting Windows app...
call flutter run -d windows
goto :end

:simple_web
echo.
echo ========================================
echo    Running Simple Version on Web
echo ========================================
echo Switching to simple version...
copy /y lib\main_simple.dart lib\main.dart
copy /y pubspec_simple.yaml pubspec.yaml

echo Installing dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to get dependencies
    pause
    exit /b 1
)

echo.
echo Starting simple web app...
echo Your app will open in Chrome browser at http://localhost:58080
call flutter run -d chrome --web-port=58080
goto :end

:analyze
echo.
echo ========================================
echo         Analyzing Code Only
echo ========================================
echo Installing dependencies...
call flutter pub get

echo.
echo Running Flutter analyze...
call flutter analyze
echo.
echo Analysis complete!
pause
goto :end

:deps
echo.
echo ========================================
echo      Installing Dependencies Only
echo ========================================
call flutter pub get
echo.
echo Dependencies installed successfully!
pause
goto :end

:web_option
echo.
echo ========================================
echo       Alternative: Online Flutter
echo ========================================
echo You can also try Flutter online:
echo 1. Go to: https://dartpad.dev/
echo 2. Create a new Flutter project
echo 3. Copy the code from lib/main_simple.dart
echo 4. Run it in the browser
echo.
pause
goto :end

:exit
echo Goodbye!
goto :end

:end
echo.
echo Script completed. Press any key to exit...
pause >nul