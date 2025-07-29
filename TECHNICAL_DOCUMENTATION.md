# Technical Documentation

This document provides comprehensive technical information about the Task Tracker app architecture, APIs, database design, and development practices.

## 🏗️ Architecture Overview

### Clean Architecture Implementation
The app follows Clean Architecture principles with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐│
│  │     Widgets     │  │    Providers    │  │   Screens    ││
│  │   (UI Components)│  │ (State Mgmt)   │  │  (Pages)     ││
│  └─────────────────┘  └─────────────────┘  └──────────────┘│
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                     Domain Layer                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐│
│  │     Models      │  │   Use Cases     │  │ Repositories ││
│  │  (Data Classes) │  │ (Business Logic)│  │ (Interfaces) ││
│  └─────────────────┘  └─────────────────┘  └──────────────┘│
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                     Data Layer                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐│
│  │   Data Sources  │  │   Repository    │  │   Services   ││
│  │   (SQLite, API) │  │ Implementations │  │ (External)   ││
│  └─────────────────┘  └─────────────────┘  └──────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### State Management with Riverpod
- **Provider-based**: All state managed through Riverpod providers
- **Reactive**: Automatic UI updates when data changes
- **Testable**: Easy dependency injection and mocking
- **Type-safe**: Compile-time error checking

## 📊 Database Design

### SQLite Schema

#### Tasks Table
```sql
CREATE TABLE tasks (
    id TEXT PRIMARY KEY,                    -- UUID v4
    title TEXT NOT NULL,                    -- Task title (max 200 chars)
    description TEXT,                       -- Optional description (max 1000 chars)
    category_id TEXT NOT NULL,              -- Foreign key to categories
    due_date TEXT,                         -- ISO 8601 date string (YYYY-MM-DD)
    due_time TEXT,                         -- ISO 8601 time string (HH:MM)
    priority TEXT DEFAULT 'medium',        -- 'low', 'medium', 'high', 'urgent'
    is_completed INTEGER DEFAULT 0,        -- Boolean (0 or 1)
    source TEXT DEFAULT 'manual',          -- 'manual', 'voice', 'chat', 'calendar'
    created_at TEXT NOT NULL,              -- ISO 8601 timestamp
    updated_at TEXT NOT NULL,              -- ISO 8601 timestamp
    completed_at TEXT,                     -- ISO 8601 timestamp when completed
    FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT
);

-- Indexes for performance
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_tasks_category_id ON tasks(category_id);
CREATE INDEX idx_tasks_is_completed ON tasks(is_completed);
CREATE INDEX idx_tasks_source ON tasks(source);
CREATE INDEX idx_tasks_priority ON tasks(priority);
CREATE INDEX idx_tasks_created_at ON tasks(created_at);

-- Full-text search index
CREATE VIRTUAL TABLE tasks_fts USING fts5(
    id UNINDEXED,
    title,
    description,
    content='tasks',
    content_rowid='rowid'
);
```

#### Categories Table
```sql
CREATE TABLE categories (
    id TEXT PRIMARY KEY,                    -- UUID v4
    name TEXT NOT NULL UNIQUE,              -- Category name (max 50 chars)
    color INTEGER NOT NULL,                 -- Color value (ARGB format)
    icon TEXT NOT NULL,                     -- Unicode emoji or icon identifier
    is_system INTEGER DEFAULT 1,           -- Whether it's a default category
    created_at TEXT NOT NULL,              -- ISO 8601 timestamp
    
    CHECK (length(name) <= 50),
    CHECK (color >= 0 AND color <= 4294967295)
);

-- Default categories data
INSERT INTO categories (id, name, color, icon, is_system, created_at) VALUES
('personal', 'Personal', 4278190335, '👤', 1, datetime('now')),
('household', 'Household', 4283215696, '🏠', 1, datetime('now')),
('work', 'Work', 4280391411, '💼', 1, datetime('now')),
('family', 'Family', 4294198554, '👨‍👩‍👧‍👦', 1, datetime('now')),
('health', 'Health', 4287365665, '🏥', 1, datetime('now')),
('finance', 'Finance', 4281165909, '💰', 1, datetime('now'));
```

#### Notifications Table
```sql
CREATE TABLE notifications (
    id TEXT PRIMARY KEY,                    -- UUID v4
    task_id TEXT NOT NULL,                  -- Foreign key to tasks
    scheduled_time TEXT NOT NULL,          -- ISO 8601 timestamp
    notification_type TEXT NOT NULL,       -- 'reminder', 'overdue', 'completion'
    interval_type TEXT,                    -- '1day', '12hours', '6hours', '1hour'
    is_sent INTEGER DEFAULT 0,             -- Boolean (0 or 1)
    created_at TEXT NOT NULL,              -- ISO 8601 timestamp
    sent_at TEXT,                          -- ISO 8601 timestamp when sent
    FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE,
    
    CHECK (notification_type IN ('reminder', 'overdue', 'completion')),
    CHECK (interval_type IN ('1day', '12hours', '6hours', '1hour') OR interval_type IS NULL)
);

-- Indexes for performance
CREATE INDEX idx_notifications_task_id ON notifications(task_id);
CREATE INDEX idx_notifications_scheduled_time ON notifications(scheduled_time);
CREATE INDEX idx_notifications_is_sent ON notifications(is_sent);
```

#### Notification Preferences Table
```sql
CREATE TABLE notification_preferences (
    id TEXT PRIMARY KEY,                    -- UUID v4
    user_id TEXT DEFAULT 'default',        -- For future multi-user support
    reminder_intervals TEXT NOT NULL,      -- JSON array of enabled intervals
    enable_completion_notifications INTEGER DEFAULT 1,
    enable_overdue_notifications INTEGER DEFAULT 1,
    quiet_hours_start TEXT,               -- HH:MM format
    quiet_hours_end TEXT,                 -- HH:MM format
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
```

### Database Migrations
The app uses a versioned migration system:

```dart
class DatabaseMigrations {
  static const int currentVersion = 3;
  
  static Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      switch (version) {
        case 1:
          await _createInitialTables(db);
          break;
        case 2:
          await _addNotificationsTable(db);
          break;
        case 3:
          await _addFullTextSearch(db);
          break;
      }
    }
  }
}
```

## 🔧 Core Services

### 1. Database Service
**Location**: `lib/core/services/database_service.dart`

```dart
class DatabaseService {
  static DatabaseService? _instance;
  Database? _database;
  
  // Singleton pattern for database connection
  static DatabaseService get instance => _instance ??= DatabaseService._();
  
  // Initialize database with migrations
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }
  
  // Performance optimizations
  Future<void> enableOptimizations() async {
    final db = await database;
    await db.execute('PRAGMA journal_mode=WAL');
    await db.execute('PRAGMA synchronous=NORMAL');
    await db.execute('PRAGMA cache_size=10000');
    await db.execute('PRAGMA temp_store=MEMORY');
  }
}
```

**Key Features**:
- Singleton pattern for connection management
- WAL mode for better concurrent performance
- Connection pooling and optimization
- Automatic migration handling
- Data integrity validation

### 2. Voice Service
**Location**: `lib/core/services/voice_service.dart`

```dart
class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final StreamController<VoiceState> _stateController = StreamController();
  
  // Initialize speech recognition
  Future<bool> initialize() async {
    return await _speechToText.initialize(
      onError: _onError,
      onStatus: _onStatus,
    );
  }
  
  // Start listening with configuration
  Future<void> startListening({
    Duration timeout = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    await _speechToText.listen(
      onResult: _onResult,
      listenFor: timeout,
      pauseFor: pauseFor,
      partialResults: true,
      localeId: 'en_US',
    );
  }
}
```

**Features**:
- Real-time speech recognition
- Partial result handling
- Error recovery and retry logic
- Permission management
- Platform-specific optimizations

### 3. Advanced NLP Service
**Location**: `lib/core/services/advanced_nlp_service.dart`

The NLP service combines multiple parsing strategies:

```dart
class AdvancedNlpService {
  final NaturalLanguageParser _parser = NaturalLanguageParser();
  
  Future<ParsedVoiceInput> parseVoiceInput(String text) async {
    // 1. Basic pattern matching (50+ patterns)
    final basicResult = await _parser.parseVoiceInput(text);
    
    // 2. Enhanced date processing with Jiffy
    if (basicResult.dateConfidence < 0.7) {
      final jiffyDate = await _parseWithJiffy(text);
      if (jiffyDate != null) {
        return basicResult.copyWith(parsedDate: jiffyDate);
      }
    }
    
    // 3. Machine learning confidence scoring
    return _enhanceWithMLScoring(basicResult);
  }
}
```

**NLP Patterns**:
- **Date Patterns**: 50+ regex patterns for date recognition
- **Time Patterns**: 25+ patterns for time parsing
- **Priority Detection**: Keyword-based priority extraction
- **Category Suggestion**: Content-based category prediction
- **Confidence Scoring**: ML-powered accuracy assessment

### 4. Search Service
**Location**: `lib/core/services/search_service.dart`

High-performance search with caching:

```dart
class SearchService {
  final Map<String, SearchCacheEntry> _searchCache = {};
  
  Future<SearchResults> searchTasksAdvanced({
    String? query,
    SearchFilters? filters,
    SearchSort sort = SearchSort.relevance,
    int page = 0,
    int pageSize = 20,
  }) async {
    // Check cache first
    final cacheKey = _createCacheKey(query, filters, sort, page, pageSize);
    if (_searchCache.containsKey(cacheKey)) {
      return _searchCache[cacheKey]!.results;
    }
    
    // Perform search with FTS5
    final results = await _performFtsSearch(query, filters);
    
    // Cache results
    _cacheSearchResults(cacheKey, results);
    return results;
  }
}
```

**Search Features**:
- Full-text search with FTS5
- Multi-criteria filtering
- Pagination support
- Search result caching
- Autocomplete suggestions
- Performance analytics

### 5. Notification Service
**Location**: `lib/core/services/notification_service.dart`

```dart
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }
  
  Future<void> scheduleTaskReminder(Task task, Duration beforeDue) async {
    if (task.dueDate == null) return;
    
    final scheduledTime = task.dueDateTime!.subtract(beforeDue);
    await _plugin.zonedSchedule(
      task.id.hashCode,
      'Task Reminder',
      task.title,
      tz.TZDateTime.from(scheduledTime, tz.local),
      _buildNotificationDetails(task),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
```

## 🧪 Testing Architecture

### Test Structure
```
test/
├── unit/                          # Unit tests
│   ├── models/                   # Data model tests
│   ├── services/                 # Service layer tests
│   ├── repositories/             # Repository tests
│   └── utils/                    # Utility function tests
├── widget/                       # Widget tests
│   ├── screens/                  # Screen widget tests
│   ├── widgets/                  # Component tests
│   └── features/                 # Feature widget tests
├── integration/                  # Integration tests
│   ├── user_flows/               # End-to-end user scenarios
│   ├── database/                 # Database integration tests
│   └── voice/                    # Voice integration tests
└── helpers/                      # Test utilities and mocks
    ├── mock_data.dart
    ├── test_helpers.dart
    └── widget_test_helpers.dart
```

### Test Categories

#### Unit Tests
```dart
group('NaturalLanguageParser', () {
  late NaturalLanguageParser parser;
  
  setUp(() {
    parser = NaturalLanguageParser();
  });
  
  group('Date Parsing', () {
    test('should parse "tomorrow" correctly', () async {
      final result = await parser.parseVoiceInput('buy groceries tomorrow');
      
      expect(result.parsedDate, isNotNull);
      expect(result.parsedDate!.day, DateTime.now().add(Duration(days: 1)).day);
      expect(result.dateConfidence, greaterThan(0.8));
    });
    
    test('should handle complex date expressions', () async {
      final result = await parser.parseVoiceInput('meeting next Friday at 3 PM');
      
      expect(result.parsedDate, isNotNull);
      expect(result.parsedTime, isNotNull);
      expect(result.parsedTime!.hour, 15);
      expect(result.dateConfidence, greaterThan(0.7));
    });
  });
  
  group('Category Detection', () {
    test('should detect work category from keywords', () async {
      final result = await parser.parseVoiceInput('schedule meeting with client');
      
      expect(result.suggestedCategory, 'work');
      expect(result.categoryConfidence, greaterThan(0.8));
    });
  });
});
```

#### Widget Tests
```dart
group('TaskListItem Widget', () {
  testWidgets('should display task information correctly', (tester) async {
    final task = Task.create(
      title: 'Test Task',
      categoryId: 'personal',
      priority: TaskPriority.high,
    );
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskListItem(task: task),
        ),
      ),
    );
    
    expect(find.text('Test Task'), findsOneWidget);
    expect(find.byIcon(Icons.priority_high), findsOneWidget);
  });
  
  testWidgets('should trigger completion on swipe', (tester) async {
    bool taskCompleted = false;
    final task = Task.create(title: 'Test Task', categoryId: 'personal');
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskListItem(
            task: task,
            onComplete: () => taskCompleted = true,
          ),
        ),
      ),
    );
    
    await tester.drag(find.byType(TaskListItem), Offset(300, 0));
    await tester.pumpAndSettle();
    
    expect(taskCompleted, isTrue);
  });
});
```

#### Integration Tests
```dart
group('Voice to Calendar Integration', () {
  testWidgets('should create task from voice and show on calendar', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    
    // Tap voice button
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pumpAndSettle();
    
    // Simulate voice input
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'plugins.flutter.io/speech_to_text',
      // Mock voice result
    );
    
    // Verify task creation
    expect(find.text('Buy groceries'), findsOneWidget);
    
    // Navigate to calendar
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    
    // Verify task appears on calendar
    expect(find.byType(TableCalendar), findsOneWidget);
    // Additional calendar verification logic
  });
});
```

### Mock Objects
```dart
class MockTaskRepository extends Mock implements TaskRepository {}
class MockVoiceService extends Mock implements VoiceService {}
class MockNotificationService extends Mock implements NotificationService {}

// Test data factory
class TestDataFactory {
  static Task createTask({
    String? title,
    String? categoryId,
    TaskPriority? priority,
    DateTime? dueDate,
  }) {
    return Task.create(
      title: title ?? 'Test Task',
      categoryId: categoryId ?? 'personal',
      priority: priority ?? TaskPriority.medium,
      dueDate: dueDate,
    );
  }
  
  static List<Task> createTaskList(int count) {
    return List.generate(count, (index) => createTask(title: 'Task $index'));
  }
}
```

## 📈 Performance Optimizations

### Database Optimizations
1. **WAL Mode**: Write-Ahead Logging for better concurrency
2. **Prepared Statements**: Reuse compiled SQL queries
3. **Batch Operations**: Group multiple operations together
4. **Index Optimization**: Strategic indexes on frequently queried columns
5. **Connection Pooling**: Reuse database connections

### Memory Management
1. **Object Pooling**: Reuse expensive objects (RegExp, DateFormat)
2. **Lazy Loading**: Load data only when needed
3. **Image Caching**: Cache category icons and other assets
4. **Stream Disposal**: Proper cleanup of stream subscriptions
5. **Weak References**: Prevent memory leaks in callbacks

### UI Performance
1. **ListView.builder**: Efficient list rendering for large datasets
2. **RepaintBoundary**: Isolate expensive widgets from repaints
3. **Const Constructors**: Reduce widget tree rebuilds
4. **Image Optimization**: Compressed assets and proper sizing
5. **Animation Optimization**: Use Transform instead of changing layouts

### Voice Processing
1. **Background Processing**: Parse voice input on separate isolate
2. **Result Caching**: Cache parsed results for recent inputs
3. **Debouncing**: Prevent rapid repeated processing
4. **Memory Cleanup**: Dispose audio resources properly

## 🔐 Security Considerations

### Data Protection
1. **Local Storage**: All data stored locally in SQLite
2. **No Cloud Dependencies**: Offline-first architecture
3. **Permission Handling**: Minimal required permissions
4. **Data Validation**: Input sanitization and validation
5. **SQL Injection Prevention**: Parameterized queries only

### Privacy
1. **Voice Data**: Processed locally, not sent to servers
2. **Chat Integration**: Only processes locally shared text
3. **No Analytics**: No user behavior tracking
4. **No Third-party SDKs**: Minimal external dependencies

## 🚀 Deployment and CI/CD

### Build Configuration
```yaml
# pubspec.yaml build configuration
flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
  
  # Platform-specific configuration
  android:
    package: com.tasktracker.app
    minSdkVersion: 24
    targetSdkVersion: 34
    
  ios:
    bundle-id: com.tasktracker.app
    minimum-version: 12.0
```

### Platform Permissions

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />

<!-- Intent filters for chat integration -->
<activity android:name=".MainActivity" android:exported="true">
  <intent-filter>
    <action android:name="android.intent.action.SEND" />
    <category android:name="android.intent.category.DEFAULT" />
    <data android:mimeType="text/plain" />
  </intent-filter>
</activity>
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to microphone for voice input</string>

<key>UIBackgroundModes</key>
<array>
  <string>background-processing</string>
  <string>remote-notification</string>
</array>
```

### Build Commands
```bash
# Development build
flutter run --debug

# Release build for Android
flutter build apk --release --target-platform android-arm64

# Release build for iOS (requires macOS)
flutter build ios --release

# Build with flavor (if implemented)
flutter build apk --flavor production --release
```

## 📚 API Reference

### Core Models

#### Task Model
```dart
class Task {
  final String id;
  final String title;
  final String? description;
  final String categoryId;
  final DateTime? dueDate;
  final TimeOfDay? dueTime;
  final TaskPriority priority;
  final bool isCompleted;
  final TaskSource source;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  
  // Computed properties
  bool get isOverdue => dueDateTime?.isBefore(DateTime.now()) ?? false;
  bool get isDueToday => /* implementation */;
  bool get isDueTomorrow => /* implementation */;
  DateTime? get dueDateTime => /* combines dueDate and dueTime */;
}
```

#### Category Model
```dart
class Category {
  final String id;
  final String name;
  final Color color;
  final String icon;
  final bool isSystem;
  final DateTime createdAt;
  
  static List<Category> getDefaultCategories() => [
    Category(id: 'personal', name: 'Personal', color: Colors.blue, icon: '👤'),
    Category(id: 'household', name: 'Household', color: Colors.green, icon: '🏠'),
    // ... other default categories
  ];
}
```

### Repository Interfaces

#### TaskRepository
```dart
abstract class TaskRepository {
  Future<List<Task>> getAllTasks();
  Future<List<Task>> getPendingTasks();
  Future<List<Task>> getCompletedTasks();
  Future<List<Task>> getOverdueTasks();
  Future<List<Task>> getTasksByCategory(String categoryId);
  Future<List<Task>> getTasksByDateRange(DateTime start, DateTime end);
  Future<List<Task>> searchTasks(String query);
  
  Future<Task?> getTaskById(String id);
  Future<String> createTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String id);
  Future<void> completeTask(String id);
  
  Stream<List<Task>> watchAllTasks();
  Stream<List<Task>> watchTasksByCategory(String categoryId);
}
```

### Service Interfaces

#### VoiceService
```dart
abstract class VoiceService {
  Future<bool> initialize();
  Future<bool> isAvailable();
  Future<void> startListening();
  Future<void> stopListening();
  Stream<VoiceState> get stateStream;
  void dispose();
}
```

#### NotificationService
```dart
abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermissions();
  Future<void> scheduleTaskReminder(Task task, Duration beforeDue);
  Future<void> cancelTaskReminders(String taskId);
  Future<void> showTaskCompletion(Task task);
  Future<List<PendingNotificationRequest>> getPendingNotifications();
}
```

## 📋 Development Checklist

### Pre-commit Checklist
- [ ] Code formatted with `flutter format .`
- [ ] No analysis issues with `flutter analyze`
- [ ] All tests passing with `flutter test`
- [ ] Updated documentation if API changed
- [ ] Added tests for new features
- [ ] Verified on both iOS and Android (if applicable)

### Release Checklist
- [ ] Version number updated in `pubspec.yaml`
- [ ] Changelog updated with new features and fixes
- [ ] All integration tests passing
- [ ] Performance testing completed
- [ ] App size analysis completed
- [ ] Store listing updated (if needed)
- [ ] Privacy policy updated (if needed)

---

This technical documentation provides a comprehensive overview of the Task Tracker app's architecture, implementation details, and development practices. For specific implementation questions or contributions, please refer to the source code and feel free to open issues or discussions on GitHub.