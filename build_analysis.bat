@echo off
echo =============================================
echo FLUTTER BUILD ANALYSIS REPORT
echo =============================================
echo.

echo [INFO] Project: Task Tracker App
echo [INFO] Flutter SDK Check...
flutter --version
echo.

echo =============================================
echo STEP 1/5: DEPENDENCY ANALYSIS
echo =============================================
echo [INFO] Checking pubspec.yaml for known issues...

findstr /C:"sdk:" pubspec.yaml
if %ERRORLEVEL% EQ 0 echo [PASS] SDK version constraints found

findstr /C:"flutter:" pubspec.yaml
if %ERRORLEVEL% EQ 0 echo [PASS] Flutter version constraints found

echo.
echo [INFO] Running flutter pub get...
flutter pub get 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] flutter pub get failed - dependency resolution issues
    echo [SUGGESTION] Check for version conflicts in pubspec.yaml
    echo.
    goto :error
) else (
    echo [PASS] Dependencies resolved successfully
)

echo.
echo =============================================
echo STEP 2/5: DEPENDENCY CONFLICTS CHECK
echo =============================================
echo [INFO] Checking for dependency conflicts...
flutter pub deps --style=compact 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Dependency tree analysis failed
    echo [SUGGESTION] May indicate version conflicts
) else (
    echo [PASS] Dependency tree analysis completed
)

echo.
echo =============================================
echo STEP 3/5: CODE ANALYSIS
echo =============================================
echo [INFO] Running static analysis...
flutter analyze 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Static analysis found issues
    echo [SUGGESTION] Fix linting errors and warnings above
    echo.
    goto :error
) else (
    echo [PASS] No static analysis issues found
)

echo.
echo =============================================
echo STEP 4/5: ANDROID BUILD PREREQUISITES
echo =============================================
echo [INFO] Checking Android configuration...

if exist "android\app\build.gradle" (
    echo [PASS] Android build.gradle exists
    findstr /C:"compileSdk 35" android\app\build.gradle >nul
    if %ERRORLEVEL% EQ 0 (
        echo [PASS] Compile SDK version 35 configured
    ) else (
        echo [WARNING] Compile SDK may not be latest
    )
    
    findstr /C:"minSdkVersion 21" android\app\build.gradle >nul
    if %ERRORLEVEL% EQ 0 (
        echo [PASS] Minimum SDK version 21 configured
    ) else (
        echo [WARNING] Check minimum SDK version
    )
) else (
    echo [ERROR] Android build.gradle not found
    goto :error
)

if exist "android\app\src\main\AndroidManifest.xml" (
    echo [PASS] AndroidManifest.xml exists
    findstr /C:"RECORD_AUDIO" android\app\src\main\AndroidManifest.xml >nul
    if %ERRORLEVEL% EQ 0 (
        echo [PASS] Voice recognition permissions configured
    ) else (
        echo [WARNING] Voice permissions may be missing
    )
) else (
    echo [ERROR] AndroidManifest.xml not found
    goto :error
)

echo.
echo =============================================
echo STEP 5/5: BUILD EXECUTION
echo =============================================
echo [INFO] Attempting debug APK build...
flutter build apk --debug --verbose 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] APK build failed
    echo [SUGGESTION] Check build output above for specific errors
    echo [COMMON ISSUES]:
    echo   - Java version compatibility (requires JDK 17)
    echo   - Android SDK tools not installed
    echo   - Gradle configuration issues
    echo   - Native code compilation errors
    echo.
    goto :error
) else (
    echo [PASS] APK build completed successfully
)

echo.
echo =============================================
echo BUILD ANALYSIS COMPLETE - SUCCESS!
echo =============================================
echo [SUMMARY] All build steps completed successfully:
echo   ✓ Dependencies resolved without conflicts
echo   ✓ Static analysis passed
echo   ✓ Android configuration valid
echo   ✓ Debug APK build successful
echo.
echo [APK LOCATION] build\app\outputs\apk\debug\app-debug.apk
echo [NEXT STEPS] You can now install and test the app
echo =============================================
pause
exit /b 0

:error
echo.
echo =============================================
echo BUILD ANALYSIS COMPLETE - ERRORS FOUND
echo =============================================
echo [SUMMARY] Build process failed. Review errors above.
echo [TROUBLESHOOTING]:
echo   1. Ensure Flutter SDK is properly installed
echo   2. Check Android SDK and build tools
echo   3. Verify Java JDK 17 is installed
echo   4. Review pubspec.yaml for dependency conflicts
echo   5. Fix any code analysis errors
echo =============================================
pause
exit /b 1