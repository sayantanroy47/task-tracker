# Task Tracker - PowerShell Quick Start Script
# This script helps you quickly set up and run the Flutter Task Tracker app on Windows

param(
    [string]$Mode = "menu"
)

# Color functions for better output
function Write-Success { param([string]$Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Error { param([string]$Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Warning { param([string]$Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Info { param([string]$Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Header { param([string]$Message) Write-Host "`n🚀 $Message" -ForegroundColor Magenta }

Clear-Host
Write-Host @"

========================================
   Task Tracker - PowerShell Quick Start
========================================
"@ -ForegroundColor Cyan

# Check Flutter installation
try {
    $null = Get-Command flutter -ErrorAction Stop
    $flutterVersion = flutter --version 2>$null
    Write-Success "Flutter detected!"
} catch {
    Write-Error "Flutter is not installed or not in PATH"
    Write-Host @"

Please install Flutter first:
1. Download from: https://docs.flutter.dev/get-started/install/windows
2. Extract to C:\flutter
3. Add C:\flutter\bin to your PATH
4. Run 'flutter doctor' to verify installation

"@
    Read-Host "Press Enter to exit"
    exit 1
}

function Show-Menu {
    Write-Host @"

========================================
        Choose an option:
========================================
1. 🚀 Quick Start (Web Browser - Recommended)
2. 🖥️  Run on Windows Desktop  
3. 📱 Run on Android Device/Emulator
4. 🔧 Install Dependencies Only
5. 🧪 Run Tests
6. 🔍 Analyze Code
7. 📊 Full Verification (Build + Test)
8. ❓ Help & Troubleshooting
9. 🚪 Exit

"@ -ForegroundColor White
}

function Start-WebApp {
    Write-Header "Starting Task Tracker on Web"
    
    Write-Info "Installing dependencies..."
    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to get dependencies"
        return
    }
    
    Write-Info "Starting web server..."
    Write-Host "📱 Your app will open at: http://localhost:58080" -ForegroundColor Yellow
    Write-Host "🛑 Press Ctrl+C to stop the server" -ForegroundColor Yellow
    
    flutter run -d chrome --web-port=58080
}

function Start-WindowsApp {
    Write-Header "Starting Task Tracker on Windows Desktop"
    
    # Enable Windows desktop
    flutter config --enable-windows-desktop | Out-Null
    
    Write-Info "Installing dependencies..."
    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to get dependencies"
        return
    }
    
    Write-Info "Starting Windows desktop app..."
    flutter run -d windows
}

function Start-AndroidApp {
    Write-Header "Starting Task Tracker on Android"
    
    Write-Info "Checking for Android devices..."
    flutter devices
    
    Write-Info "Installing dependencies..."
    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to get dependencies"
        return
    }
    
    Write-Warning "Make sure you have an Android device connected or emulator running"
    flutter run
}

function Install-Dependencies {
    Write-Header "Installing Dependencies"
    
    flutter pub get
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Dependencies installed successfully!"
    } else {
        Write-Error "Failed to install dependencies"
    }
}

function Run-Tests {
    Write-Header "Running Tests"
    
    Write-Info "Installing dependencies..."
    flutter pub get
    
    Write-Info "Running all tests..."
    flutter test
    if ($LASTEXITCODE -eq 0) {
        Write-Success "All tests passed!"
    } else {
        Write-Warning "Some tests failed - check output above"
    }
}

function Run-Analysis {
    Write-Header "Analyzing Code"
    
    Write-Info "Installing dependencies..."
    flutter pub get
    
    Write-Info "Running static analysis..."
    flutter analyze
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Analysis passed - no issues found!"
    } else {
        Write-Warning "Analysis found issues - check output above"
    }
}

function Run-FullVerification {
    Write-Header "Full Build Verification"
    Write-Info "This will run a complete verification of the app..."
    
    $steps = @(
        @{ Name = "Installing dependencies"; Command = { flutter pub get } },
        @{ Name = "Running code analysis"; Command = { flutter analyze } },
        @{ Name = "Running tests"; Command = { flutter test } },
        @{ Name = "Testing debug build"; Command = { flutter build apk --debug } }
    )
    
    $stepNumber = 1
    foreach ($step in $steps) {
        Write-Info "$stepNumber️⃣ $($step.Name)..."
        & $step.Command
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Step failed: $($step.Name)"
            Write-Host "`n❌ Verification FAILED" -ForegroundColor Red
            Write-Host "Please check the errors above and fix them." -ForegroundColor Yellow
            return
        }
        $stepNumber++
    }
    
    Write-Host @"

🎉 ========================================
     Full Verification SUCCESSFUL!
========================================
"@ -ForegroundColor Green
    
    Write-Success "Dependencies installed"
    Write-Success "Code analysis passed"
    Write-Success "All tests passed"
    Write-Success "Debug build successful"
    Write-Host "`nYour Task Tracker app is ready to run!" -ForegroundColor Cyan
}

function Show-Help {
    Write-Header "Help & Troubleshooting"
    
    Write-Host @"

🔧 COMMON ISSUES:

1. "Flutter not found"
   - Install Flutter from: https://docs.flutter.dev/get-started/install/windows
   - Add Flutter to your PATH environment variable
   - Restart PowerShell after installation

2. "No connected devices"
   - For web: Use option 1 (runs in Chrome browser)
   - For Windows: Use option 2 (desktop app)
   - For Android: Connect device or start Android emulator

3. "Build failed"
   - Run "flutter doctor" to check setup
   - Try "flutter clean" then "flutter pub get"
   - Check that you have the latest Flutter version

4. "Dependency issues"
   - Make sure you have internet connection
   - Try deleting pubspec.lock and running "flutter pub get"

📱 ABOUT TASK TRACKER:
This is a cross-platform voice-powered task management app with:
• Voice-to-text task creation with natural language processing
• Calendar integration with task scheduling
• Smart notifications and reminders
• Chat integration for extracting tasks from messages
• Search and filtering capabilities
• Offline-first design with local SQLite storage

🆘 Need more help?
• Check README.md in the project folder
• Visit: https://docs.flutter.dev/
• GitHub Issues: Report bugs and get support

"@ -ForegroundColor White
}

# Handle direct mode parameters
switch ($Mode.ToLower()) {
    "web" { Start-WebApp; exit }
    "windows" { Start-WindowsApp; exit }
    "android" { Start-AndroidApp; exit }
    "test" { Run-Tests; exit }
    "analyze" { Run-Analysis; exit }
    "verify" { Run-FullVerification; exit }
    "deps" { Install-Dependencies; exit }
}

# Interactive menu
while ($true) {
    Show-Menu
    $choice = Read-Host "Enter your choice (1-9)"
    
    switch ($choice) {
        "1" { Start-WebApp }
        "2" { Start-WindowsApp }
        "3" { Start-AndroidApp }
        "4" { Install-Dependencies }
        "5" { Run-Tests }
        "6" { Run-Analysis }
        "7" { Run-FullVerification }
        "8" { Show-Help }
        "9" { 
            Write-Host "`nThanks for using Task Tracker! 👋" -ForegroundColor Cyan
            Write-Host "💡 Quick tip: You can run this script anytime with: .\quick_start.ps1" -ForegroundColor Yellow
            exit 
        }
        default { 
            Write-Warning "Invalid choice. Please try again." 
        }
    }
    
    if ($choice -ne "8" -and $choice -ne "9") {
        Write-Host "`nPress Enter to return to menu..." -ForegroundColor Gray
        Read-Host
    }
}