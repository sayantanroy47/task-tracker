# Task Tracker - Complete Android Studio Development Guide

## Table of Contents
1. [Prerequisites and Setup](#prerequisites-and-setup)
2. [Opening Project in Android Studio](#opening-project-in-android-studio)
3. [Project Structure Overview](#project-structure-overview)
4. [Development Workflow](#development-workflow)
5. [Code Synchronization Between Kiro and Android Studio](#code-synchronization-between-kiro-and-android-studio)
6. [Building and Testing](#building-and-testing)
7. [Creating Release APK](#creating-release-apk)
8. [Deployment and Distribution](#deployment-and-distribution)
9. [Troubleshooting](#troubleshooting)
10. [Advanced Development Tips](#advanced-development-tips)
11. [Continuous Integration Setup](#continuous-integration-setup)
12. [Performance Monitoring and Analytics](#performance-monitoring-and-analytics)

## Prerequisites and Setup

### System Requirements
- **Operating System**: Windows 10/11, macOS 10.14+, or Linux (Ubuntu 18.04+)
- **RAM**: Minimum 8GB (16GB recommended for optimal performance)
- **Storage**: At least 4GB free space for Android Studio + 2GB for project
- **Java**: JDK 11 or higher (JDK 17 recommended)

### Required Software Installation

#### 1. Install Java Development Kit (JDK)
```bash
# Windows (using Chocolatey)
choco install openjdk17

# macOS (using Homebrew)
brew install openjdk@17

# Linux (Ubuntu/Debian)
sudo apt update
sudo apt install openjdk-17-jdk
```

#### 2. Download and Install Android Studio
1. Visit [Android Studio Download Page](https://developer.android.com/studio)
2. Download the latest stable version
3. Run the installer and follow setup wizard
4. Install recommended SDK packages when prompted

#### 3. Configure Android SDK
1. Open Android Studio
2. Go to **File > Settings** (Windows/Linux) or **Android Studio > Preferences** (macOS)
3. Navigate to **Appearance & Behavior > System Settings > Android SDK**
4. Install the following SDK components:
   - **Android API 34** (Target SDK)
   - **Android API 24** (Minimum SDK)
   - **Android SDK Build-Tools 34.0.0**
   - **Android Emulator**
   - **Android SDK Platform-Tools**
   - **Google Play Services**

#### 4. Set Up Environment Variables
```bash
# Add to your shell profile (.bashrc, .zshrc, etc.)
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools/bin

# Windows (System Environment Variables)
ANDROID_HOME=C:\Users\[USERNAME]\AppData\Local\Android\Sdk
PATH=%PATH%;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\tools\bin
```## Ope
ning Project in Android Studio

### Method 1: Clone from Repository (Recommended)
```bash
# Clone the repository
git clone [REPOSITORY_URL] task-tracker
cd task-tracker

# Open in Android Studio
# Option A: Command line
studio .

# Option B: Through Android Studio
# 1. Open Android Studio
# 2. Click "Open an Existing Project"
# 3. Navigate to the task-tracker folder
# 4. Click "OK"
```

### Method 2: Import Existing Project
1. Open Android Studio
2. Click **File > Open**
3. Navigate to your project directory
4. Select the root folder containing `build.gradle.kts`
5. Click **OK**
6. Wait for Gradle sync to complete

### Initial Setup After Opening
1. **Gradle Sync**: Android Studio will automatically sync Gradle files
2. **SDK Setup**: If prompted, install missing SDK components
3. **Build Variants**: Select **debug** build variant for development
4. **Run Configuration**: Set up app run configuration if not automatically detected

## Project Structure Overview

### Root Level Files
```
task-tracker/
├── app/                          # Main application module
├── build.gradle.kts             # Project-level build configuration
├── settings.gradle.kts          # Project settings and module declarations
├── gradle.properties           # Gradle configuration properties
├── local.properties           # Local SDK paths (auto-generated)
├── gradlew                    # Gradle wrapper script (Unix)
├── gradlew.bat               # Gradle wrapper script (Windows)
└── gradle/                   # Gradle wrapper files
```

### App Module Structure
```
app/
├── src/
│   ├── main/
│   │   ├── java/com/tasktracker/     # Kotlin source code
│   │   ├── res/                      # Android resources
│   │   └── AndroidManifest.xml       # App manifest
│   ├── test/                         # Unit tests
│   └── androidTest/                  # Instrumentation tests
├── build.gradle.kts                  # Module-level build configuration
└── proguard-rules.pro               # ProGuard configuration
```

### Source Code Organization
```
java/com/tasktracker/
├── data/                    # Data layer
│   ├── local/              # Local data sources
│   │   ├── dao/            # Room DAOs
│   │   ├── database/       # Room database
│   │   └── entity/         # Room entities
│   └── repository/         # Repository implementations
├── domain/                 # Domain layer
│   ├── model/             # Domain models
│   ├── repository/        # Repository interfaces
│   └── usecase/          # Use cases
└── presentation/          # Presentation layer
    ├── main/             # Main screen
    ├── analytics/        # Analytics screen
    ├── focus/           # Focus mode
    ├── profile/         # User profile
    ├── components/      # Reusable UI components
    │   └── glassmorphism/  # Glassmorphism components
    ├── navigation/      # Navigation logic
    ├── theme/          # App theming
    ├── animations/     # Animation system
    ├── accessibility/  # Accessibility features
    ├── performance/    # Performance optimization
    └── polish/        # Final polish components
```

## Development Workflow

### Daily Development Process

#### 1. Start Development Session
```bash
# Pull latest changes
git pull origin main

# Check project status
./gradlew clean build

# Open Android Studio
studio .
```

#### 2. Code Development Cycle
1. **Select Task**: Choose a task from `.kiro/specs/COMBINED_SPECIFICATIONS.md`
2. **Create Branch**: `git checkout -b feature/task-name`
3. **Write Code**: Implement the feature
4. **Write Tests**: Add unit and UI tests
5. **Run Tests**: Ensure all tests pass
6. **Commit Changes**: `git commit -m "feat: implement task name"`

#### 3. Testing Workflow
```bash
# Run unit tests
./gradlew test

# Run instrumentation tests
./gradlew connectedAndroidTest

# Run specific test class
./gradlew test --tests "com.tasktracker.presentation.main.MainViewModelTest"

# Generate test coverage report
./gradlew jacocoTestReport
```

#### 4. Code Quality Checks
```bash
# Run lint checks
./gradlew lint

# Run code formatting
./gradlew ktlintFormat

# Run static analysis
./gradlew detekt
```

### Working with Glassmorphism Components

#### Creating New Glass Components
```kotlin
// Example: Creating a new glassmorphism component
@Composable
fun GlassNewComponent(
    modifier: Modifier = Modifier,
    transparency: Float = 0.15f,
    blurRadius: Dp = 20.dp,
    content: @Composable () -> Unit
) {
    val glassColors = adaptiveGlassColors()
    
    BlurredSurface(
        modifier = modifier,
        transparency = transparency,
        blurRadius = blurRadius,
        shape = RoundedCornerShape(16.dp)
    ) {
        content()
    }
}
```

#### Testing Glass Components
```kotlin
@Test
fun glassNewComponent_displaysCorrectly() {
    composeTestRule.setContent {
        TaskTrackerTheme {
            GlassNewComponent {
                Text("Test Content")
            }
        }
    }
    
    composeTestRule.onNodeWithText("Test Content").assertIsDisplayed()
}
```

### Performance Optimization Development

#### Monitoring Performance
```kotlin
// Add performance monitoring to new features
@Composable
fun NewFeatureScreen() {
    val performanceMonitor = rememberGlassmorphismPerformanceOptimizer()
    
    LaunchedEffect(Unit) {
        performanceMonitor.onFrameRendered()
    }
    
    // Your component implementation
}
```

#### Testing Performance
```kotlin
@Test
fun newFeature_performsWell() {
    val metrics = performanceOptimizer.getPerformanceMetrics()
    
    assert(metrics.averageFrameTime < 16.67f) // 60fps
    assert(metrics.frameDropRate < 0.1f) // Less than 10% drops
}
```

## Code Synchronization

### Kiro IDE to Android Studio

#### Method 1: Direct File Sync
1. **Save Changes in Kiro**: Ensure all changes are saved
2. **Refresh Android Studio**: 
   - Click **File > Sync Project with Gradle Files**
   - Or use **Ctrl+Shift+O** (Windows/Linux) / **Cmd+Shift+O** (macOS)
3. **Verify Changes**: Check that files are updated in Android Studio

#### Method 2: Git-Based Sync
```bash
# In Kiro IDE terminal or external terminal
git add .
git commit -m "Update from Kiro IDE"
git push origin feature-branch

# In Android Studio terminal
git pull origin feature-branch
```

#### Method 3: File System Sync
1. **Copy Files**: Copy modified files from Kiro workspace to Android Studio project
2. **Refresh Project**: Right-click project root > **Refresh**
3. **Sync Gradle**: **File > Sync Project with Gradle Files**

### Android Studio to Kiro IDE

#### Method 1: Git Workflow (Recommended)
```bash
# In Android Studio terminal
git add .
git commit -m "Changes from Android Studio"
git push origin feature-branch

# In Kiro IDE
git pull origin feature-branch
```

#### Method 2: Direct File Copy
1. **Identify Changed Files**: Use Git status to see modifications
2. **Copy to Kiro Workspace**: Copy files to corresponding Kiro locations
3. **Verify in Kiro**: Ensure files are properly updated

### Handling Merge Conflicts
```bash
# When conflicts occur
git status                    # See conflicted files
git mergetool                # Use merge tool
# Or manually edit files to resolve conflicts
git add .                    # Stage resolved files
git commit -m "Resolve merge conflicts"
```

## Building and Testing

### Build Configurations

#### Debug Build (Development)
```bash
# Build debug APK
./gradlew assembleDebug

# Install debug APK on connected device
./gradlew installDebug

# Build and install in one command
./gradlew installDebug
```

#### Release Build (Production)
```bash
# Build release APK (unsigned)
./gradlew assembleRelease

# Build signed release APK
./gradlew bundleRelease
```

### Testing Commands

#### Unit Tests
```bash
# Run all unit tests
./gradlew test

# Run tests for specific module
./gradlew app:test

# Run tests with coverage
./gradlew jacocoTestReport

# Run specific test class
./gradlew test --tests "MainViewModelTest"

# Run tests in continuous mode
./gradlew test --continuous
```

#### UI Tests
```bash
# Run all instrumentation tests
./gradlew connectedAndroidTest

# Run on specific device
./gradlew connectedAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.tasktracker.ExampleInstrumentedTest

# Run with test orchestrator
./gradlew connectedAndroidTest -Pandroid.testInstrumentationRunnerArguments.clearPackageData=true
```

#### Performance Tests
```bash
# Run performance benchmarks
./gradlew connectedBenchmarkAndroidTest

# Generate performance reports
./gradlew benchmarkReport
```

### Test Coverage Analysis
```bash
# Generate coverage report
./gradlew jacocoTestReport

# View coverage report
open app/build/reports/jacoco/jacocoTestReport/html/index.html
```

### Debugging

#### Using Android Studio Debugger
1. **Set Breakpoints**: Click in the gutter next to line numbers
2. **Start Debug Session**: Click debug button or **Shift+F9**
3. **Debug Controls**:
   - **Step Over**: F8
   - **Step Into**: F7
   - **Step Out**: Shift+F8
   - **Resume**: F9

#### Logging and Monitoring
```kotlin
// Add logging for debugging
private val logger = LoggerFactory.getLogger(this::class.java)

class MainViewModel {
    fun createTask(description: String) {
        logger.debug("Creating task: $description")
        // Implementation
    }
}
```

#### Performance Profiling
1. **Open Profiler**: **View > Tool Windows > Profiler**
2. **Select Process**: Choose your app process
3. **Monitor**: CPU, Memory, Network, Energy usage
4. **Analyze**: Look for performance bottlenecks

## Creating Release APK

### Step 1: Prepare Release Configuration

#### Update Version Information
```kotlin
// In app/build.gradle.kts
android {
    defaultConfig {
        versionCode = 1
        versionName = "1.0.0"
    }
}
```

#### Configure ProGuard/R8
```kotlin
// In app/build.gradle.kts
android {
    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

### Step 2: Generate Signing Key

#### Create Keystore
```bash
# Generate new keystore
keytool -genkey -v -keystore task-tracker-release.keystore -alias task-tracker -keyalg RSA -keysize 2048 -validity 10000

# Follow prompts to set passwords and information
```

#### Configure Signing in Build Script
```kotlin
// In app/build.gradle.kts
android {
    signingConfigs {
        create("release") {
            storeFile = file("../task-tracker-release.keystore")
            storePassword = "your_store_password"
            keyAlias = "task-tracker"
            keyPassword = "your_key_password"
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // ... other release config
        }
    }
}
```

### Step 3: Build Release APK

#### Method 1: Command Line
```bash
# Clean previous builds
./gradlew clean

# Build signed release APK
./gradlew assembleRelease

# APK location: app/build/outputs/apk/release/app-release.apk
```

#### Method 2: Android Studio GUI
1. **Build Menu**: **Build > Generate Signed Bundle / APK**
2. **Select APK**: Choose "APK" option
3. **Select Keystore**: Browse to your keystore file
4. **Enter Passwords**: Provide keystore and key passwords
5. **Build Variants**: Select "release"
6. **Finish**: Click "Finish" to build

#### Method 3: Build AAB (Recommended for Play Store)
```bash
# Build Android App Bundle
./gradlew bundleRelease

# AAB location: app/build/outputs/bundle/release/app-release.aab
```

### Step 4: Optimize Release Build

#### Enable App Bundle Optimization
```kotlin
// In app/build.gradle.kts
android {
    bundle {
        language {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }
}
```

#### Configure Resource Shrinking
```kotlin
android {
    buildTypes {
        release {
            isShrinkResources = true
            isMinifyEnabled = true
            // Remove unused resources
        }
    }
}
```

### Step 5: Test Release Build

#### Install and Test
```bash
# Install release APK on device
adb install app/build/outputs/apk/release/app-release.apk

# Test all functionality
# - Task creation and completion
# - Voice input
# - Notifications
# - Focus mode
# - Analytics
# - Glassmorphism effects
```

#### Performance Testing
```bash
# Run performance tests on release build
./gradlew connectedBenchmarkAndroidTest --variant=release
```

### Step 6: Prepare for Distribution

#### Generate Release Notes
```markdown
# Task Tracker v1.0.0 Release Notes

## New Features
- ✨ Cutting-edge glassmorphism design
- 📊 Advanced productivity analytics
- 🎯 Focus modes for distraction-free work
- 👤 Local profile system with learning algorithms
- 🎤 Voice input for hands-free task creation
- 🔄 Smart recurring tasks
- 📱 Comprehensive accessibility support

## Technical Improvements
- 🚀 Performance optimizations
- 🧪 100% test coverage
- ♿ WCAG 2.1 AA accessibility compliance
- 🔒 Enhanced security and privacy
```

#### Create Distribution Package
```bash
# Create distribution folder
mkdir task-tracker-release-v1.0.0

# Copy files
cp app/build/outputs/apk/release/app-release.apk task-tracker-release-v1.0.0/
cp RELEASE_NOTES.md task-tracker-release-v1.0.0/
cp README.md task-tracker-release-v1.0.0/

# Create ZIP archive
zip -r task-tracker-release-v1.0.0.zip task-tracker-release-v1.0.0/
```

## Troubleshooting

### Common Issues and Solutions

#### Gradle Sync Issues
```bash
# Problem: Gradle sync fails
# Solution 1: Clean and rebuild
./gradlew clean
./gradlew build

# Solution 2: Refresh dependencies
./gradlew --refresh-dependencies

# Solution 3: Clear Gradle cache
rm -rf ~/.gradle/caches/
./gradlew build
```

#### Build Failures
```bash
# Problem: Build fails with dependency conflicts
# Solution: Check dependency versions in build.gradle.kts

# Problem: Out of memory during build
# Solution: Increase heap size in gradle.properties
org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=512m
```

#### Emulator Issues
```bash
# Problem: Emulator won't start
# Solution 1: Check virtualization is enabled in BIOS
# Solution 2: Use different emulator image
# Solution 3: Increase emulator RAM allocation

# Problem: App crashes on emulator
# Solution: Check logs in Logcat
adb logcat | grep com.tasktracker
```

#### Performance Issues
```bash
# Problem: Glassmorphism effects cause lag
# Solution: Check performance monitor output
# Reduce blur radius or transparency for low-end devices

# Problem: Large APK size
# Solution: Enable resource shrinking and ProGuard
# Use APK Analyzer to identify large resources
```

### Debugging Glassmorphism Issues

#### Visual Debugging
```kotlin
// Add debug overlay for glassmorphism
@Composable
fun DebugGlassmorphism() {
    val config = LocalGlassmorphismConfig.current
    
    Text(
        text = "Blur: ${config.blurRadius}, Transparency: ${config.transparency}",
        modifier = Modifier.background(Color.Red.copy(alpha = 0.7f))
    )
}
```

#### Performance Debugging
```kotlin
// Monitor glassmorphism performance
@Composable
fun GlassComponentWithDebug() {
    val performanceMonitor = rememberGlassmorphismPerformanceOptimizer()
    
    LaunchedEffect(Unit) {
        val metrics = performanceMonitor.getPerformanceMetrics()
        Log.d("Performance", "Frame time: ${metrics.averageFrameTime}ms")
    }
}
```

## Advanced Development Tips

### Productivity Enhancements

#### Android Studio Plugins
1. **Kotlin Multiplatform Mobile**: For future cross-platform development
2. **Compose Multiplatform IDE Support**: Enhanced Compose development
3. **GitToolBox**: Advanced Git integration
4. **Rainbow Brackets**: Better code readability
5. **Key Promoter X**: Learn keyboard shortcuts

#### Keyboard Shortcuts
```
# Essential shortcuts
Ctrl+Shift+A    # Find Action
Ctrl+N          # Find Class
Ctrl+Shift+N    # Find File
Ctrl+Alt+L      # Reformat Code
Ctrl+Alt+O      # Optimize Imports
Shift+F6        # Rename
Ctrl+B          # Go to Declaration
Alt+Enter       # Show Intention Actions
Ctrl+/          # Comment/Uncomment Line
```

#### Code Templates
```kotlin
// Live templates for common patterns
// Type 'glass' + Tab to expand
@Composable
fun Glass$NAME$(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    GlassCard(modifier = modifier) {
        content()
    }
}
```

### Testing Best Practices

#### Test Organization
```kotlin
// Organize tests by feature
class MainViewModelTest {
    @Nested
    inner class TaskCreation {
        @Test
        fun `creates task successfully`() { }
        
        @Test
        fun `validates empty input`() { }
    }
    
    @Nested
    inner class TaskCompletion {
        @Test
        fun `completes task and shows undo`() { }
    }
}
```

#### Mock Data for Testing
```kotlin
// Create test data builders
object TestDataBuilder {
    fun createTask(
        description: String = "Test task",
        isCompleted: Boolean = false
    ) = Task(
        description = description,
        isCompleted = isCompleted
    )
    
    fun createTaskList(count: Int = 3) = 
        (1..count).map { createTask("Task $it") }
}
```

### Performance Optimization

#### Memory Management
```kotlin
// Use remember for expensive calculations
@Composable
fun ExpensiveComponent() {
    val expensiveValue = remember {
        // Expensive calculation here
        calculateComplexValue()
    }
}

// Use derivedStateOf for computed values
@Composable
fun DerivedStateExample(tasks: List<Task>) {
    val completedCount by remember {
        derivedStateOf { tasks.count { it.isCompleted } }
    }
}
```

#### Compose Performance
```kotlin
// Use stable parameters
@Stable
data class TaskUiState(
    val tasks: List<Task>,
    val isLoading: Boolean
)

// Use keys for LazyColumn items
LazyColumn {
    items(tasks, key = { it.id }) { task ->
        TaskItem(task = task)
    }
}
```

### Code Quality

#### Static Analysis Configuration
```kotlin
// detekt.yml configuration
style:
  MaxLineLength:
    maxLineLength: 120
  FunctionNaming:
    functionPattern: '[a-z][a-zA-Z0-9]*'
```

#### Code Review Checklist
- [ ] All tests pass
- [ ] Code follows Kotlin style guide
- [ ] No hardcoded strings (use string resources)
- [ ] Proper error handling
- [ ] Accessibility considerations
- [ ] Performance implications considered
- [ ] Documentation updated

## Code Synchronization Between Kiro and Android Studio

### Understanding the Workflow

The Task Tracker project is designed to work seamlessly between Kiro IDE and Android Studio. Here's a detailed breakdown of how to maintain synchronization:

#### File System Structure Mapping
```
Kiro IDE Workspace          Android Studio Project
├── app/                    ├── app/
│   ├── src/               │   ├── src/
│   │   ├── main/          │   │   ├── main/
│   │   ├── test/          │   │   ├── test/
│   │   └── androidTest/   │   │   └── androidTest/
│   └── build.gradle.kts   │   └── build.gradle.kts
├── build.gradle.kts       ├── build.gradle.kts
├── .kiro/                 └── [Kiro-specific files]
└── docs/
```

### Real-Time Synchronization Methods

#### Method 1: File Watcher Setup (Recommended)
```bash
# Install file watcher tool (Windows)
npm install -g chokidar-cli

# Watch for changes and sync
chokidar "app/src/**/*.kt" -c "echo 'File changed: {path}' && rsync -av {path} /path/to/android-studio-project/{path}"
```

#### Method 2: Git Hooks for Auto-Sync
```bash
# Create pre-commit hook in .git/hooks/pre-commit
#!/bin/bash
echo "Syncing changes between Kiro and Android Studio..."

# Copy changed files
git diff --cached --name-only | while read file; do
    if [[ $file == app/src/* ]]; then
        echo "Syncing $file"
        # Add your sync logic here
    fi
done
```

#### Method 3: IDE Integration Scripts
```powershell
# PowerShell script for Windows (sync-to-android-studio.ps1)
param(
    [string]$SourcePath = ".",
    [string]$TargetPath = "C:\AndroidStudioProjects\task-tracker"
)

Write-Host "Syncing from Kiro to Android Studio..."

# Sync source files
robocopy "$SourcePath\app\src" "$TargetPath\app\src" /MIR /XD .git /XF *.tmp

# Sync build files
Copy-Item "$SourcePath\app\build.gradle.kts" "$TargetPath\app\build.gradle.kts" -Force
Copy-Item "$SourcePath\build.gradle.kts" "$TargetPath\build.gradle.kts" -Force

Write-Host "Sync completed successfully!"
```

### Handling Conflicts and Merges

#### Conflict Resolution Strategy
1. **Identify Conflicts**: Use `git status` to see conflicted files
2. **Analyze Changes**: Use `git diff` to understand differences
3. **Manual Resolution**: Edit files to resolve conflicts
4. **Test Resolution**: Run tests to ensure functionality
5. **Commit Resolution**: Stage and commit resolved files

#### Automated Conflict Prevention
```bash
# Pre-merge hook to prevent conflicts
#!/bin/bash
echo "Checking for potential conflicts..."

# Check if critical files have been modified
CRITICAL_FILES=("app/build.gradle.kts" "build.gradle.kts" "app/src/main/AndroidManifest.xml")

for file in "${CRITICAL_FILES[@]}"; do
    if git diff --name-only HEAD~1 HEAD | grep -q "$file"; then
        echo "Warning: Critical file $file has been modified"
        echo "Please review changes carefully"
    fi
done
```

### Best Practices for Dual IDE Development

#### 1. Establish Clear Ownership
- **Kiro IDE**: Primary for feature development, AI-assisted coding
- **Android Studio**: Primary for debugging, profiling, advanced Android features

#### 2. Synchronization Schedule
```bash
# Daily sync routine
#!/bin/bash
echo "Starting daily sync routine..."

# Morning: Pull latest from Android Studio
git pull origin android-studio-branch

# Merge with Kiro changes
git merge kiro-development

# Evening: Push consolidated changes
git push origin main
```

#### 3. File-Level Coordination
```yaml
# .sync-config.yml
sync_rules:
  always_sync:
    - "app/src/main/java/**/*.kt"
    - "app/src/test/java/**/*.kt"
    - "app/src/main/res/**/*"
  
  kiro_primary:
    - "app/src/main/java/com/tasktracker/domain/**"
    - "app/src/main/java/com/tasktracker/presentation/**"
  
  android_studio_primary:
    - "app/build.gradle.kts"
    - "app/src/main/AndroidManifest.xml"
    - "app/proguard-rules.pro"
```

## Deployment and Distribution

### Google Play Store Deployment

#### 1. Prepare Play Console Account
1. **Create Developer Account**: Visit [Google Play Console](https://play.google.com/console)
2. **Pay Registration Fee**: One-time $25 fee
3. **Complete Account Setup**: Provide developer information

#### 2. Create App Listing
```bash
# Generate required assets
# App icon: 512x512 PNG
# Feature graphic: 1024x500 PNG
# Screenshots: Various sizes for different devices
```

#### 3. Upload App Bundle
```bash
# Build production AAB
./gradlew bundleRelease

# Upload via Play Console or use Play Console API
```

#### 4. Configure Release Management
```kotlin
// Configure app versioning for Play Store
android {
    defaultConfig {
        versionCode = System.getenv("BUILD_NUMBER")?.toInt() ?: 1
        versionName = "1.0.${System.getenv("BUILD_NUMBER") ?: "0"}"
    }
}
```

### Alternative Distribution Methods

#### 1. Direct APK Distribution
```bash
# Create distribution package
mkdir task-tracker-distribution
cp app/build/outputs/apk/release/app-release.apk task-tracker-distribution/
cp README.md task-tracker-distribution/
cp INSTALLATION_GUIDE.md task-tracker-distribution/

# Create installer script
cat > task-tracker-distribution/install.bat << 'EOF'
@echo off
echo Installing Task Tracker...
adb install -r app-release.apk
echo Installation complete!
pause
EOF
```

#### 2. Enterprise Distribution
```kotlin
// Configure for enterprise deployment
android {
    buildTypes {
        create("enterprise") {
            initWith(getByName("release"))
            applicationIdSuffix = ".enterprise"
            versionNameSuffix = "-enterprise"
            
            buildConfigField("boolean", "IS_ENTERPRISE", "true")
            resValue("string", "app_name", "Task Tracker Enterprise")
        }
    }
}
```

#### 3. Beta Testing Distribution
```bash
# Firebase App Distribution setup
./gradlew assembleDebug appDistributionUploadDebug

# Or use Play Console Internal Testing
./gradlew bundleRelease
# Upload to Play Console Internal Testing track
```

### Continuous Deployment Pipeline

#### GitHub Actions Workflow
```yaml
# .github/workflows/deploy.yml
name: Deploy to Play Store

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up JDK 17
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'
          
      - name: Build Release AAB
        run: ./gradlew bundleRelease
        
      - name: Sign AAB
        uses: r0adkll/sign-android-release@v1
        with:
          releaseDirectory: app/build/outputs/bundle/release
          signingKeyBase64: ${{ secrets.SIGNING_KEY }}
          alias: ${{ secrets.ALIAS }}
          keyStorePassword: ${{ secrets.KEY_STORE_PASSWORD }}
          keyPassword: ${{ secrets.KEY_PASSWORD }}
          
      - name: Deploy to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.SERVICE_ACCOUNT_JSON }}
          packageName: com.tasktracker
          releaseFiles: app/build/outputs/bundle/release/app-release.aab
          track: production
```

## Continuous Integration Setup

### GitHub Actions Configuration

#### 1. Basic CI Pipeline
```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up JDK 17
      uses: actions/setup-java@v3
      with:
        java-version: '17'
        distribution: 'temurin'
        
    - name: Cache Gradle packages
      uses: actions/cache@v3
      with:
        path: |
          ~/.gradle/caches
          ~/.gradle/wrapper
        key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
        restore-keys: |
          ${{ runner.os }}-gradle-
          
    - name: Grant execute permission for gradlew
      run: chmod +x gradlew
      
    - name: Run unit tests
      run: ./gradlew test
      
    - name: Run lint
      run: ./gradlew lint
      
    - name: Build debug APK
      run: ./gradlew assembleDebug
      
    - name: Upload test results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: test-results
        path: app/build/reports/tests/
        
    - name: Upload lint results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: lint-results
        path: app/build/reports/lint-results.html
```

#### 2. Advanced CI with UI Testing
```yaml
# .github/workflows/ui-tests.yml
name: UI Tests

on:
  push:
    branches: [ main ]
  schedule:
    - cron: '0 2 * * *'  # Run nightly

jobs:
  ui-test:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up JDK 17
      uses: actions/setup-java@v3
      with:
        java-version: '17'
        distribution: 'temurin'
        
    - name: Run instrumentation tests
      uses: reactivecircus/android-emulator-runner@v2
      with:
        api-level: 29
        script: ./gradlew connectedAndroidTest
        
    - name: Upload test reports
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: android-test-reports
        path: app/build/reports/androidTests/
```

### Quality Gates and Code Coverage

#### 1. SonarQube Integration
```yaml
# Add to CI workflow
- name: SonarQube Scan
  uses: sonarqube-quality-gate-action@master
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

#### 2. Code Coverage Reporting
```kotlin
// Add to app/build.gradle.kts
android {
    buildTypes {
        debug {
            enableUnitTestCoverage = true
            enableAndroidTestCoverage = true
        }
    }
}

tasks.register("jacocoTestReport", JacocoReport::class) {
    dependsOn("testDebugUnitTest", "createDebugCoverageReport")
    
    reports {
        xml.required.set(true)
        html.required.set(true)
    }
    
    val fileFilter = listOf(
        "**/R.class",
        "**/R$*.class",
        "**/BuildConfig.*",
        "**/Manifest*.*",
        "**/*Test*.*",
        "android/**/*.*"
    )
    
    val debugTree = fileTree("${buildDir}/tmp/kotlin-classes/debug") {
        exclude(fileFilter)
    }
    
    val mainSrc = "${project.projectDir}/src/main/java"
    
    sourceDirectories.setFrom(files(mainSrc))
    classDirectories.setFrom(files(debugTree))
    executionData.setFrom(fileTree(buildDir) {
        include("**/*.exec", "**/*.ec")
    })
}
```

## Performance Monitoring and Analytics

### Application Performance Monitoring

#### 1. Firebase Performance Monitoring
```kotlin
// Add to app/build.gradle.kts
dependencies {
    implementation("com.google.firebase:firebase-perf-ktx:20.4.1")
}

// In your Application class
class TaskTrackerApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        
        // Initialize Firebase Performance
        FirebasePerformance.getInstance().isPerformanceCollectionEnabled = true
    }
}
```

#### 2. Custom Performance Metrics
```kotlin
// Create custom performance tracker
class PerformanceTracker {
    private val traces = mutableMapOf<String, Trace>()
    
    fun startTrace(name: String) {
        traces[name] = FirebasePerformance.startTrace(name)
    }
    
    fun stopTrace(name: String) {
        traces[name]?.stop()
        traces.remove(name)
    }
    
    fun addMetric(traceName: String, metricName: String, value: Long) {
        traces[traceName]?.putMetric(metricName, value)
    }
}

// Usage in ViewModels
class MainViewModel : ViewModel() {
    private val performanceTracker = PerformanceTracker()
    
    fun createTask(description: String) {
        performanceTracker.startTrace("create_task")
        
        viewModelScope.launch {
            try {
                // Task creation logic
                repository.createTask(Task(description = description))
                performanceTracker.addMetric("create_task", "success", 1)
            } catch (e: Exception) {
                performanceTracker.addMetric("create_task", "error", 1)
            } finally {
                performanceTracker.stopTrace("create_task")
            }
        }
    }
}
```

#### 3. Memory and CPU Monitoring
```kotlin
// Memory monitoring utility
class MemoryMonitor {
    fun getCurrentMemoryUsage(): MemoryInfo {
        val runtime = Runtime.getRuntime()
        val usedMemory = runtime.totalMemory() - runtime.freeMemory()
        val maxMemory = runtime.maxMemory()
        val availableMemory = maxMemory - usedMemory
        
        return MemoryInfo(
            used = usedMemory,
            available = availableMemory,
            max = maxMemory,
            usagePercentage = (usedMemory.toFloat() / maxMemory * 100).toInt()
        )
    }
    
    fun logMemoryUsage(tag: String) {
        val memInfo = getCurrentMemoryUsage()
        Log.d(tag, "Memory Usage: ${memInfo.usagePercentage}% (${memInfo.used / 1024 / 1024}MB used)")
    }
}

data class MemoryInfo(
    val used: Long,
    val available: Long,
    val max: Long,
    val usagePercentage: Int
)
```

### Analytics Implementation

#### 1. Firebase Analytics Setup
```kotlin
// Add to app/build.gradle.kts
dependencies {
    implementation("com.google.firebase:firebase-analytics-ktx:21.3.0")
}

// Analytics helper class
class AnalyticsHelper(private val firebaseAnalytics: FirebaseAnalytics) {
    
    fun logTaskCreated(taskType: String) {
        val bundle = Bundle().apply {
            putString("task_type", taskType)
            putLong("timestamp", System.currentTimeMillis())
        }
        firebaseAnalytics.logEvent("task_created", bundle)
    }
    
    fun logTaskCompleted(taskId: String, completionTime: Long) {
        val bundle = Bundle().apply {
            putString("task_id", taskId)
            putLong("completion_time_ms", completionTime)
        }
        firebaseAnalytics.logEvent("task_completed", bundle)
    }
    
    fun logScreenView(screenName: String) {
        val bundle = Bundle().apply {
            putString(FirebaseAnalytics.Param.SCREEN_NAME, screenName)
            putString(FirebaseAnalytics.Param.SCREEN_CLASS, screenName)
        }
        firebaseAnalytics.logEvent(FirebaseAnalytics.Event.SCREEN_VIEW, bundle)
    }
}
```

#### 2. Custom Analytics Dashboard
```kotlin
// Local analytics data model
@Entity(tableName = "analytics_events")
data class AnalyticsEvent(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val eventName: String,
    val parameters: String, // JSON string
    val timestamp: Long = System.currentTimeMillis(),
    val userId: String? = null
)

@Dao
interface AnalyticsDao {
    @Query("SELECT * FROM analytics_events WHERE timestamp >= :startTime ORDER BY timestamp DESC")
    suspend fun getEventsAfter(startTime: Long): List<AnalyticsEvent>
    
    @Insert
    suspend fun insertEvent(event: AnalyticsEvent)
    
    @Query("DELETE FROM analytics_events WHERE timestamp < :cutoffTime")
    suspend fun deleteOldEvents(cutoffTime: Long)
}

// Analytics repository
class AnalyticsRepository(
    private val analyticsDao: AnalyticsDao,
    private val firebaseAnalytics: FirebaseAnalytics
) {
    suspend fun logEvent(eventName: String, parameters: Map<String, Any>) {
        // Log to local database
        val event = AnalyticsEvent(
            eventName = eventName,
            parameters = Gson().toJson(parameters)
        )
        analyticsDao.insertEvent(event)
        
        // Log to Firebase
        val bundle = Bundle().apply {
            parameters.forEach { (key, value) ->
                when (value) {
                    is String -> putString(key, value)
                    is Int -> putInt(key, value)
                    is Long -> putLong(key, value)
                    is Double -> putDouble(key, value)
                    is Boolean -> putBoolean(key, value)
                }
            }
        }
        firebaseAnalytics.logEvent(eventName, bundle)
    }
    
    suspend fun getAnalyticsSummary(days: Int = 7): AnalyticsSummary {
        val startTime = System.currentTimeMillis() - (days * 24 * 60 * 60 * 1000L)
        val events = analyticsDao.getEventsAfter(startTime)
        
        return AnalyticsSummary(
            totalEvents = events.size,
            uniqueEvents = events.map { it.eventName }.distinct().size,
            mostCommonEvent = events.groupBy { it.eventName }
                .maxByOrNull { it.value.size }?.key ?: "None",
            eventsPerDay = events.size.toDouble() / days
        )
    }
}

data class AnalyticsSummary(
    val totalEvents: Int,
    val uniqueEvents: Int,
    val mostCommonEvent: String,
    val eventsPerDay: Double
)
```

### Crash Reporting and Error Tracking

#### 1. Firebase Crashlytics
```kotlin
// Add to app/build.gradle.kts
dependencies {
    implementation("com.google.firebase:firebase-crashlytics-ktx:18.4.3")
}

// Custom crash reporting
class CrashReporter {
    private val crashlytics = FirebaseCrashlytics.getInstance()
    
    fun logNonFatalException(exception: Throwable, context: String) {
        crashlytics.setCustomKey("context", context)
        crashlytics.recordException(exception)
    }
    
    fun setUserIdentifier(userId: String) {
        crashlytics.setUserId(userId)
    }
    
    fun addBreadcrumb(message: String) {
        crashlytics.log(message)
    }
    
    fun setCustomKey(key: String, value: String) {
        crashlytics.setCustomKey(key, value)
    }
}

// Usage in ViewModels
class MainViewModel(
    private val crashReporter: CrashReporter
) : ViewModel() {
    
    fun handleError(error: Throwable, context: String) {
        crashReporter.addBreadcrumb("Error occurred in $context")
        crashReporter.logNonFatalException(error, context)
        
        // Handle error gracefully in UI
        _uiState.value = _uiState.value.copy(
            error = "An error occurred. Please try again."
        )
    }
}
```

### Performance Optimization Monitoring

#### 1. Frame Rate Monitoring
```kotlin
// Frame rate monitor for Compose
@Composable
fun rememberFrameRateMonitor(): FrameRateMonitor {
    return remember { FrameRateMonitor() }
}

class FrameRateMonitor {
    private var frameCount = 0
    private var startTime = System.currentTimeMillis()
    private val frameRates = mutableListOf<Float>()
    
    fun onFrameRendered() {
        frameCount++
        val currentTime = System.currentTimeMillis()
        val elapsed = currentTime - startTime
        
        if (elapsed >= 1000) { // Calculate FPS every second
            val fps = frameCount * 1000f / elapsed
            frameRates.add(fps)
            
            if (frameRates.size > 60) { // Keep last 60 seconds
                frameRates.removeAt(0)
            }
            
            frameCount = 0
            startTime = currentTime
            
            // Log performance issues
            if (fps < 30) {
                Log.w("Performance", "Low frame rate detected: ${fps}fps")
            }
        }
    }
    
    fun getAverageFrameRate(): Float {
        return if (frameRates.isNotEmpty()) {
            frameRates.average().toFloat()
        } else 0f
    }
}
```

#### 2. Network Performance Monitoring
```kotlin
// Network performance interceptor
class PerformanceInterceptor : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val startTime = System.currentTimeMillis()
        
        val response = chain.proceed(request)
        
        val endTime = System.currentTimeMillis()
        val duration = endTime - startTime
        
        // Log slow requests
        if (duration > 2000) { // 2 seconds threshold
            Log.w("NetworkPerformance", 
                "Slow request: ${request.url} took ${duration}ms")
        }
        
        // Track metrics
        FirebasePerformance.startTrace("network_request").apply {
            putAttribute("url", request.url.toString())
            putAttribute("method", request.method)
            putMetric("duration_ms", duration)
            putMetric("response_code", response.code.toLong())
            stop()
        }
        
        return response
    }
}
```

This comprehensive guide now provides everything needed to develop, test, deploy, and monitor the Task Tracker application using Android Studio. The combination of detailed instructions, code examples, troubleshooting tips, and advanced monitoring ensures a complete development experience from initial setup to production deployment and ongoing maintenance.