@echo off
echo Running flutter pub get...
flutter pub get

echo.
echo Running flutter analyze...
flutter analyze

echo.
echo Running flutter build apk --debug...
flutter build apk --debug

echo.
echo Build process completed!
pause