# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Important Steps

You always spawn multiple agents. You are allowed to spawn any number of agents you want or even choose from the agents I have. Agents are located in .claude\agents

# Planning 
When a SPEC is planned, divide it into steps, update the .claude\specs\@TASKS.md file. Follow the @TASKS.md file and always keep it updated after finishing a task.

# TODOs
When you are skipping some implementation, add this is the .claude\specs\@TODO.md File for future reference and implementation.

# FEATURE_IDEAS

When I ask you about a feature idea, or you come up with a new idea /feature, add it to .claude\specs\@IDEAS.md


## Development Commands

### Flutter Commands
```bash
# Get dependencies
flutter pub get

# Run the app (debug mode)
flutter run

# Build APK for Android
flutter build apk

# Build for iOS (requires macOS)
flutter build ios

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format .

# Clean build cache
flutter clean
```

### Platform-Specific Commands
```bash
# Android emulator
flutter emulators --launch <emulator_id>

# List connected devices
flutter devices

# Install APK on device
flutter install
```

## Project Overview

This is a **cross-platform task tracker app** built with Flutter, designed for forgetful people who need voice-powered task management with calendar integration and chat parsing capabilities.

### Core Technologies
- **Framework**: Flutter 3.16+
- **Language**: Dart 3.2+
- **State Management**: Riverpod 2.4+
- **Database**: SQLite (sqflite 2.3+)
- **Voice Recognition**: speech_to_text 6.6+
- **Calendar**: table_calendar 3.0+
- **Notifications**: flutter_local_notifications 16.3+
- **Date Parsing**: intl + jiffy for natural language processing

### Architecture Structure

```
lib/
├── core/                    # Core utilities and services
│   ├── constants/          # App constants
│   ├── utils/              # Utility functions
│   └── services/           # Core services
├── features/               # Feature modules
│   ├── tasks/              # Task management
│   ├── calendar/           # Calendar integration
│   ├── voice/              # Voice input processing
│   └── categories/         # Task categorization
├── shared/                 # Shared components
│   ├── widgets/            # Reusable UI components
│   ├── models/             # Data models
│   └── providers/          # Riverpod providers
└── main.dart              # App entry point
```

### Key Features (MVP)
1. **Voice Input**: Speech-to-text with natural language date/time parsing
2. **Calendar Integration**: Built-in calendar view with task scheduling
3. **Task Categories**: 6 default categories (Personal, Household, Work, Family, Health, Finance)
4. **Smart Notifications**: Configurable intervals (1 day/12hrs/6hrs/1hr)
5. **Chat Integration**: Parse tasks from WhatsApp/Facebook messages
6. **Minimal UI**: Clean, intuitive interface with swipe gestures
7. **Offline-First**: Local SQLite storage, no backend required initially

### Database Schema
```sql
-- Tasks table
tasks: id, title, description, category_id, due_date, due_time, 
       priority, completed, created_at, updated_at, source

-- Categories table  
categories: id, name, color, icon, is_system, created_at

-- Notifications table
notifications: id, task_id, scheduled_time, type, sent
```

### Voice Processing Pipeline
1. **Speech Recognition**: Convert voice to text
2. **NLP Processing**: Extract dates, times, and task content
3. **Task Creation**: Automatically create tasks with parsed info
4. **Calendar Integration**: Schedule tasks and set notifications
5. **User Confirmation**: Allow review before saving

### Chat Integration Strategy
1. **Intent Filters**: Handle shared text from messaging apps
2. **Content Parsing**: Extract task-like content from messages
3. **Smart Categorization**: Auto-assign categories based on content
4. **Date Extraction**: Parse dates from message context
5. **Manual Review**: User confirmation for auto-created tasks

### Development Guidelines
- **Minimal Design**: Focus on simplicity and usability
- **Free Libraries Only**: All dependencies are open-source
- **Cross-Platform**: Single codebase for iOS and Android
- **Performance**: Optimize for smooth voice processing and UI
- **Accessibility**: Ensure screen reader compatibility
- **Local Storage**: Offline-first approach with future cloud sync capability

### Important Files
- `lib/main.dart`: App initialization with Riverpod
- `pubspec.yaml`: Dependencies and project configuration
- `android/app/src/main/AndroidManifest.xml`: Android permissions and intents
- `lib/core/services/`: Voice, database, and notification services
- `lib/features/`: Core feature implementations

### Future Scalability
- Backend integration for cloud sync
- Multi-device support
- Advanced AI features
- Team collaboration features