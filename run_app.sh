#!/bin/bash

echo "========================================"
echo "   Task Tracker - Flutter App Runner"
echo "========================================"
echo

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter is not installed or not in PATH"
    echo
    echo "Please install Flutter from: https://flutter.dev/docs/get-started/install"
    echo "Or use the web option below."
    web_option
fi

echo "Flutter detected! Checking available devices..."
echo

# List available devices
flutter devices

echo
echo "========================================"
echo "        Choose Running Option:"
echo "========================================"
echo "1. Run on Chrome/Web Browser (Recommended)"
echo "2. Run on Linux Desktop"
echo "3. Run simple version on Web"
echo "4. Just analyze code (no running)"
echo "5. Install dependencies only"
echo "6. Exit"
echo
read -p "Enter your choice (1-6): " choice

case $choice in
    1)
        run_web
        ;;
    2)
        run_linux
        ;;
    3)
        run_simple_web
        ;;
    4)
        analyze_only
        ;;
    5)
        install_deps
        ;;
    6)
        echo "Goodbye!"
        exit 0
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

run_web() {
    echo
    echo "========================================"
    echo "    Running on Web Browser (Chrome)"
    echo "========================================"
    echo "Installing dependencies..."
    flutter pub get
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to get dependencies"
        exit 1
    fi

    echo
    echo "Starting web server..."
    echo "Your app will open in Chrome browser at http://localhost:58080"
    echo "Press Ctrl+C to stop the server"
    echo
    flutter run -d chrome --web-port=58080
}

run_linux() {
    echo
    echo "========================================"
    echo "      Running on Linux Desktop"
    echo "========================================"
    echo "Installing dependencies..."
    flutter pub get
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to get dependencies"
        exit 1
    fi

    echo
    echo "Starting Linux app..."
    flutter run -d linux
}

run_simple_web() {
    echo
    echo "========================================"
    echo "   Running Simple Version on Web"
    echo "========================================"
    echo "Switching to simple version..."
    cp lib/main_simple.dart lib/main.dart
    cp pubspec_simple.yaml pubspec.yaml

    echo "Installing dependencies..."
    flutter pub get
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to get dependencies"
        exit 1
    fi

    echo
    echo "Starting simple web app..."
    echo "Your app will open in Chrome browser at http://localhost:58080"
    flutter run -d chrome --web-port=58080
}

analyze_only() {
    echo
    echo "========================================"
    echo "        Analyzing Code Only"
    echo "========================================"
    echo "Installing dependencies..."
    flutter pub get

    echo
    echo "Running Flutter analyze..."
    flutter analyze
    echo
    echo "Analysis complete!"
    read -p "Press Enter to continue..."
}

install_deps() {
    echo
    echo "========================================"
    echo "     Installing Dependencies Only"
    echo "========================================"
    flutter pub get
    echo
    echo "Dependencies installed successfully!"
    read -p "Press Enter to continue..."
}

web_option() {
    echo
    echo "========================================"
    echo "      Alternative: Online Flutter"
    echo "========================================"
    echo "You can also try Flutter online:"
    echo "1. Go to: https://dartpad.dev/"
    echo "2. Create a new Flutter project"
    echo "3. Copy the code from lib/main_simple.dart"
    echo "4. Run it in the browser"
    echo
    read -p "Press Enter to continue..."
    exit 0
}

echo
echo "Script completed."