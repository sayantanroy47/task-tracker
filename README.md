# Task Tracker App

A sophisticated, voice-powered cross-platform task management application built with Flutter, designed specifically for forgetful people who need intelligent task creation, calendar integration, and chat parsing capabilities.

![Flutter](https://img.shields.io/badge/Flutter-3.16+-blue?logo=flutter) ![Dart](https://img.shields.io/badge/Dart-3.2+-darkblue?logo=dart) ![License](https://img.shields.io/badge/License-MIT-green) ![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey)

## ✨ Features

### 🎤 Advanced Voice Input
- **Natural Language Processing**: Understands complex voice commands like "Remind me to buy groceries tomorrow at 3 PM"
- **Smart Date/Time Parsing**: Recognizes 50+ date patterns including "next Friday", "in 3 weeks", "end of month"
- **Category Detection**: Automatically suggests task categories based on content
- **Priority Extraction**: Identifies urgency keywords like "urgent", "ASAP", "important"
- **Real-time Feedback**: Visual voice input overlay with processing states
- **Confidence Scoring**: Machine learning-powered accuracy assessment

### 📅 Comprehensive Calendar Integration
- **Multiple View Modes**: Month, week, and agenda views
- **Task Visualization**: Color-coded task indicators on calendar dates
- **Voice-Calendar Bridge**: Voice input tasks instantly appear on calendar
- **Quick Task Creation**: Tap any date to create tasks with pre-filled dates
- **Smart Navigation**: Today button, date range filtering, smooth animations

### 💬 Intelligent Chat Integration
- **Multi-App Support**: Works with WhatsApp, Facebook Messenger, SMS, and more
- **Intent Filters**: Automatically receives shared text from messaging apps
- **NLP Task Extraction**: Parses messages to identify actionable tasks
- **Confidence Scoring**: Smart suggestions with accuracy ratings
- **Review Interface**: Batch approval system for extracted tasks
- **Source Tracking**: Knows which tasks came from which apps

### 🔍 Advanced Search & Analytics
- **Full-Text Search**: Lightning-fast search across all task content
- **Smart Filters**: Filter by category, priority, date range, completion status
- **Search Suggestions**: Autocomplete with recent tasks and smart predictions
- **Performance Analytics**: Track completion rates and productivity trends
- **Export Capabilities**: Backup data in JSON, CSV, or Markdown formats

### 🎨 Polished User Experience
- **Material Design 3**: Modern, consistent design language
- **Dark Mode Support**: Automatic system theme detection
- **Smooth Animations**: 60fps performance with micro-interactions
- **Gesture Support**: Swipe-to-complete, pull-to-refresh
- **Accessibility**: Full screen reader support, high contrast mode
- **Cross-Platform**: Single codebase running on iOS and Android

### 🔔 Smart Notification System
- **Multiple Reminder Intervals**: 1 day, 12 hours, 6 hours, 1 hour before due
- **Notification Actions**: Complete, snooze, or reschedule from notifications
- **Do Not Disturb**: Respects system quiet hours
- **Custom Scheduling**: User-configurable reminder preferences

## 🚀 Quick Start

### Prerequisites
- Flutter 3.16 or higher
- Dart 3.2 or higher
- Android Studio / VS Code with Flutter extensions
- iOS development: Xcode 15+ (macOS only)
- Android development: Android SDK 24+ (API level 24)

### 🪟 Windows Users - One-Click Setup

**Option 1: Batch Script (Command Prompt)**
```cmd
# Double-click quick_start.bat or run in Command Prompt
quick_start.bat
```

**Option 2: PowerShell Script (Modern)**
```powershell
# Right-click -> Run with PowerShell, or in PowerShell:
.\quick_start.ps1

# Quick commands:
.\quick_start.ps1 -Mode web     # Start on web browser
.\quick_start.ps1 -Mode verify  # Full build verification
.\quick_start.ps1 -Mode test    # Run tests only
```

### Manual Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/task-tracker.git
   cd task-tracker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure permissions** (Already set up in the project)
   - **Android**: Microphone, notifications, and intent filters configured
   - **iOS**: Microphone usage description and background capabilities

4. **Run the app**
   ```bash
   # Debug mode (recommended for development)
   flutter run

   # Release mode
   flutter run --release
   ```

### Platform-Specific Setup

#### Android
- Minimum API level: 24 (Android 7.0)
- Target API level: 34 (Android 14)
- Permissions: `RECORD_AUDIO`, `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`

#### iOS
- Minimum version: iOS 12.0
- Required capabilities: Background processing, push notifications
- Privacy usage descriptions for microphone access

## 📱 Usage Guide

### Voice Input
1. **Tap the voice button** (microphone icon) on any screen
2. **Speak naturally**: "Remind me to call mom tomorrow at 2 PM"
3. **Review suggestions**: Check parsed date, time, and category
4. **Confirm or edit**: Tap "Create Task" or modify details
5. **View on calendar**: Task automatically appears on the calendar

#### Voice Command Examples
- "Buy groceries this Saturday morning"
- "Doctor appointment next Friday at 3:30 PM"
- "Pay electricity bill by end of month"
- "Important: Submit project report tomorrow"
- "Call dentist for checkup in 2 weeks"

### Calendar Features
1. **Navigate months**: Swipe left/right or use navigation arrows
2. **Select dates**: Tap any date to see tasks for that day
3. **Create tasks**: Use the floating action button for date-specific tasks
4. **View modes**: Switch between month, week, and agenda views
5. **Quick actions**: Tap "Today" to jump to current date

### Chat Integration
1. **Share text** from any messaging app using the share button
2. **Select "Task Tracker"** from the share menu
3. **Review extracted tasks** in the task review screen
4. **Approve or edit** suggestions before adding to your task list
5. **Track sources** to see which tasks came from which apps

### Search & Filtering
1. **Quick search**: Use the search bar on the main screen
2. **Advanced filters**: Tap the filter icon for detailed options
3. **Smart suggestions**: Get autocomplete as you type
4. **Quick filters**: Use preset buttons for common searches
5. **Export data**: Access export options in settings

## 🏗️ Technical Architecture

### Core Technologies
- **Framework**: Flutter 3.16+ with Material Design 3
- **Language**: Dart 3.2+ with null safety
- **State Management**: Riverpod 2.4+ for reactive state
- **Database**: SQLite with sqflite 2.3+ for local storage
- **Voice Recognition**: speech_to_text 6.6+ with permissions
- **Calendar**: table_calendar 3.0+ with custom styling
- **Notifications**: flutter_local_notifications 16.3+
- **Date Processing**: intl + jiffy for natural language parsing

### Project Structure
```
lib/
├── core/                    # Core utilities and services
│   ├── constants/          # App-wide constants and themes
│   ├── navigation/         # Routing and navigation logic
│   ├── repositories/       # Data access layer interfaces
│   ├── services/           # Business logic services
│   └── utils/              # Helper functions and utilities
├── features/               # Feature-based modules
│   ├── tasks/              # Task management (CRUD, providers)
│   ├── calendar/           # Calendar integration and widgets
│   ├── voice/              # Voice input and NLP processing
│   ├── chat/               # Chat integration and parsing
│   ├── categories/         # Task categorization system
│   └── settings/           # App settings and preferences
├── shared/                 # Shared components across features
│   ├── models/             # Data models and enums
│   ├── providers/          # Global Riverpod providers
│   └── widgets/            # Reusable UI components
└── main.dart              # App entry point and initialization
```

### Database Schema
```sql
-- Tasks table
CREATE TABLE tasks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    category_id TEXT NOT NULL,
    due_date TEXT,
    due_time TEXT,
    priority TEXT DEFAULT 'medium',
    is_completed INTEGER DEFAULT 0,
    source TEXT DEFAULT 'manual',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (category_id) REFERENCES categories (id)
);

-- Categories table
CREATE TABLE categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    color INTEGER NOT NULL,
    icon TEXT NOT NULL,
    is_system INTEGER DEFAULT 1,
    created_at TEXT NOT NULL
);

-- Notifications table
CREATE TABLE notifications (
    id TEXT PRIMARY KEY,
    task_id TEXT NOT NULL,
    scheduled_time TEXT NOT NULL,
    notification_type TEXT NOT NULL,
    is_sent INTEGER DEFAULT 0,
    created_at TEXT NOT NULL,
    FOREIGN KEY (task_id) REFERENCES tasks (id)
);
```

### Key Services
- **DatabaseService**: SQLite operations and migrations
- **VoiceService**: Speech recognition and audio processing
- **AdvancedNlpService**: Natural language understanding
- **SearchService**: Full-text search with caching
- **NotificationService**: Local push notifications
- **ChatIntegrationService**: External app integration
- **AnalyticsService**: Usage tracking and insights

## 🧪 Development

### Running Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Test with coverage
flutter test --coverage
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
flutter format .

# Generate code (for models)
flutter packages pub run build_runner build
```

### Performance Monitoring
```bash
# Profile performance
flutter run --profile

# Check app size
flutter build apk --analyze-size

# Memory profiling
flutter run --profile --trace-startup
```

## 📊 Current Status

### ✅ Completed Features (Phase 1-2)
- ✅ **Core Architecture**: Riverpod state management, SQLite database, navigation
- ✅ **Voice Recognition**: Advanced speech-to-text with 50+ NLP patterns
- ✅ **Calendar Integration**: Full calendar with task visualization and multi-view modes
- ✅ **Task Management**: Complete CRUD operations with categories and priorities
- ✅ **Search System**: Advanced search with filters, suggestions, and analytics
- ✅ **UI/UX Polish**: Material Design 3, dark mode, smooth animations
- ✅ **Chat Integration**: Intent handling and message parsing foundation
- ✅ **Export System**: Data backup in multiple formats with integrity checking

### 🚧 In Progress (Phase 3)
- 🔄 **Smart Notifications**: Local notification system with multiple reminder intervals
- 🔄 **UI Enhancements**: Micro-interactions, gesture support, accessibility improvements
- 🔄 **Performance Optimization**: Large dataset handling, memory management

### 📋 Upcoming Features (Phase 4-5)
- 📅 **Advanced Chat Integration**: Full WhatsApp/Facebook message parsing
- 📅 **Task Analytics**: Detailed productivity insights and habit tracking
- 📅 **Notification Actions**: Complete, snooze, reschedule from notifications
- 📅 **Comprehensive Testing**: Unit, widget, and integration test coverage
- 📅 **App Store Deployment**: Final polish and store submission

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and add tests
4. Ensure all tests pass: `flutter test`
5. Commit your changes: `git commit -m 'Add amazing feature'`
6. Push to the branch: `git push origin feature/amazing-feature`
7. Submit a pull request

### Code Style
- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Write comprehensive tests for new features
- Document public APIs with dartdoc comments

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Flutter Team** for the amazing cross-platform framework
- **Riverpod** for excellent state management
- **Contributors** who have helped shape this project
- **Open Source Community** for the fantastic packages used

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/task-tracker/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/task-tracker/discussions)
- **Email**: support@tasktracker.app

---

**Built with ❤️ using Flutter**

*Making task management effortless for forgetful minds*