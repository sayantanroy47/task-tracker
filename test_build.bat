@echo off
echo =============================================
echo Testing Flutter Build Process
echo =============================================

echo.
echo [STEP 1] Running flutter pub get...
echo =============================================
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: flutter pub get failed
    pause
    exit /b 1
)

echo.
echo [STEP 2] Running flutter pub deps...
echo =============================================
flutter pub deps
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: flutter pub deps failed
    pause
    exit /b 1
)

echo.
echo [STEP 3] Running flutter analyze...
echo =============================================
flutter analyze
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: flutter analyze failed
    pause
    exit /b 1
)

echo.
echo [STEP 4] Running flutter build apk --debug...
echo =============================================
flutter build apk --debug
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: flutter build apk --debug failed
    pause
    exit /b 1
)

echo.
echo =============================================
echo BUILD PROCESS COMPLETED SUCCESSFULLY!
echo =============================================
echo All steps passed:
echo   ✓ Dependencies updated
echo   ✓ No dependency conflicts
echo   ✓ No code analysis issues
echo   ✓ APK build successful
echo =============================================
pause