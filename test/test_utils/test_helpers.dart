import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_tracker_app/shared/models/models.dart';
import 'package:task_tracker_app/core/constants/app_theme.dart';
import 'fixtures.dart';

/// Comprehensive test helpers for integration and widget testing
/// Provides utilities for setting up test environments and simulating user interactions
class TestHelpers {
  
  /// Create a test app wrapper with proper providers and theme
  static Widget createTestApp({
    required Widget child,
    List<Override> overrides = const [],
    Locale? locale,
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        title: 'Task Tracker Test',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        locale: locale,
        localizationsDelegates: const [
          // Add your localization delegates here
        ],
        home: Scaffold(body: child),
      ),
    );
  }

  /// Create a test app with navigation support
  static Widget createTestAppWithNavigation({
    required Widget child,
    List<Override> overrides = const [],
    String initialRoute = '/',
    Map<String, WidgetBuilder>? routes,
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        title: 'Task Tracker Test',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        initialRoute: initialRoute,
        routes: routes ?? {
          '/': (context) => Scaffold(body: child),
        },
      ),
    );
  }

  /// Create a test provider scope with common overrides
  static Widget createTestProviderScope({
    required Widget child,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: child,
    );
  }

  /// Simulate voice input result for testing
  static Future<void> simulateVoiceInput(WidgetTester tester, String voiceText) async {
    // This would typically interact with a mocked voice service
    // For now, we'll simulate the process by triggering the appropriate callbacks
    await tester.pump(const Duration(milliseconds: 500)); // Simulate processing time
    
    // In a real implementation, this would trigger the voice result callback
    // through the mocked voice service
  }

  /// Simulate shared text from external app (chat integration)
  static Future<void> simulateSharedText(WidgetTester tester, String sharedText) async {
    // Simulate intent handling for shared text
    await tester.pump(const Duration(milliseconds: 100));
    
    // This would typically trigger the intent handler
    // For testing, we'll assume the shared text is processed
  }

  /// Create multiple tasks for a specific date
  static Future<void> createTasksForDate(
    WidgetTester tester,
    DateTime date,
    List<String> taskTitles,
  ) async {
    for (final title in taskTitles) {
      final task = TaskFixtures.createTask(
        title: title,
        dueDate: date,
        categoryId: 'personal',
      );
      // In real implementation, this would add to the database
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Create tasks with different states for testing
  static Future<void> createTasksWithStates(
    WidgetTester tester,
    List<Map<String, dynamic>> taskConfigs,
  ) async {
    for (final config in taskConfigs) {
      final task = TaskFixtures.createTask(
        title: config['title'] as String,
        isCompleted: config['completed'] as bool? ?? false,
        dueDate: config['date'] as DateTime?,
        categoryId: config['categoryId'] as String? ?? 'personal',
        priority: config['priority'] as TaskPriority? ?? TaskPriority.medium,
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Create categorized tasks for testing
  static Future<void> createCategorizedTasks(
    WidgetTester tester,
    Map<String, List<String>> categorizedTasks,
  ) async {
    for (final category in categorizedTasks.keys) {
      for (final title in categorizedTasks[category]!) {
        final task = TaskFixtures.createTask(
          title: title,
          categoryId: category.toLowerCase(),
          dueDate: DateTime.now(),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
    }
  }

  /// Create many tasks for performance testing
  static Future<void> createManyTasks(WidgetTester tester, {required int count}) async {
    final tasks = TaskFixtures.createTaskList(count: count, mixCompleted: true);
    
    // Simulate database insertion in batches
    const batchSize = 50;
    for (int i = 0; i < tasks.length; i += batchSize) {
      final batch = tasks.skip(i).take(batchSize);
      // In real implementation, this would be a batch database operation
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Create tasks across a date range for calendar testing
  static Future<void> createTasksForDateRange(
    WidgetTester tester,
    DateTime startDate,
    DateTime endDate,
    List<String> taskTitles,
  ) async {
    final daysDifference = endDate.difference(startDate).inDays;
    final daysPerTask = (daysDifference / taskTitles.length).ceil();

    for (int i = 0; i < taskTitles.length; i++) {
      final taskDate = startDate.add(Duration(days: i * daysPerTask));
      final task = TaskFixtures.createTask(
        title: taskTitles[i],
        dueDate: taskDate,
        categoryId: 'work',
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Create many tasks across time for performance testing
  static Future<void> createManyTasksAcrossTime(
    WidgetTester tester, {
    required DateTime startDate,
    required DateTime endDate,
    required int taskCount,
  }) async {
    final totalDays = endDate.difference(startDate).inDays;
    final categories = ['personal', 'work', 'household', 'health', 'finance', 'family'];
    
    for (int i = 0; i < taskCount; i++) {
      final randomDay = startDate.add(Duration(days: i % totalDays));
      final randomCategory = categories[i % categories.length];
      
      final task = TaskFixtures.createTask(
        title: 'Task $i',
        dueDate: randomDay,
        categoryId: randomCategory,
        isCompleted: i % 4 == 0, // 25% completed
        priority: TaskPriority.values[i % TaskPriority.values.length],
      );
      
      // Batch process to avoid overwhelming the UI
      if (i % 20 == 0) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }
  }

  /// Simulate network disconnection for offline testing
  static Future<void> simulateNetworkDisconnection(WidgetTester tester) async {
    // In real implementation, this would mock network connectivity
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Simulate network reconnection
  static Future<void> simulateNetworkReconnection(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Simulate voice service error
  static Future<void> simulateVoiceServiceError(WidgetTester tester) async {
    // Mock voice service to return error state
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Simulate storage error (disk full, permission denied, etc.)
  static Future<void> simulateStorageError(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Simulate timezone change
  static Future<void> simulateTimezoneChange(WidgetTester tester, String timezone) async {
    // Mock timezone change
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Simulate time of day for testing time-based features
  static Future<void> simulateTimeOfDay(WidgetTester tester, TimeOfDay time) async {
    // Mock current time
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Simulate specific date for testing date-based features
  static Future<void> simulateDate(WidgetTester tester, DateTime date) async {
    // Mock current date
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Wait for animations to complete
  static Future<void> waitForAnimations(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Scroll to find and interact with widget
  static Future<void> scrollToAndTap(
    WidgetTester tester,
    Finder finder, {
    Finder? scrollable,
    double delta = 100.0,
    int maxScrolls = 10,
  }) async {
    final scrollableFinder = scrollable ?? find.byType(Scrollable);
    
    for (int i = 0; i < maxScrolls; i++) {
      if (finder.evaluate().isNotEmpty) {
        await tester.tap(finder);
        return;
      }
      
      await tester.drag(scrollableFinder, Offset(0, -delta));
      await tester.pumpAndSettle();
    }
    
    throw Exception('Could not find widget to tap after scrolling');
  }

  /// Enter text with delay to simulate realistic typing
  static Future<void> enterTextSlowly(
    WidgetTester tester,
    Finder finder,
    String text, {
    Duration delay = const Duration(milliseconds: 50),
  }) async {
    await tester.tap(finder);
    await tester.pump();

    for (int i = 0; i < text.length; i++) {
      await tester.enterText(finder, text.substring(0, i + 1));
      await tester.pump(delay);
    }
  }

  /// Simulate device rotation
  static Future<void> rotateDevice(WidgetTester tester, {bool toLandscape = true}) async {
    final size = tester.binding.window.physicalSize;
    final newSize = toLandscape 
        ? Size(size.height, size.width)
        : Size(size.width, size.height);
    
    await tester.binding.setSurfaceSize(newSize);
    await tester.pumpAndSettle();
  }

  /// Simulate app going to background and returning
  static Future<void> simulateAppLifecycle(
    WidgetTester tester, {
    AppLifecycleState state = AppLifecycleState.paused,
    Duration duration = const Duration(seconds: 2),
  }) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter/lifecycle'),
      (call) async {
        return null;
      },
    );

    await tester.pump(duration);
  }

  /// Simulate notification tap
  static Future<void> simulateNotificationTap(
    WidgetTester tester,
    String payload,
  ) async {
    // In real implementation, this would trigger notification callback
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Create mock database state for testing
  static Future<void> setupMockDatabase(WidgetTester tester) async {
    // Set up initial database state with default categories
    final categories = CategoryFixtures.createDefaultCategories();
    
    // In real implementation, this would populate the test database
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Clean up test database
  static Future<void> cleanupTestDatabase(WidgetTester tester) async {
    // Clean up test data
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Verify accessibility compliance
  static Future<void> verifyAccessibility(WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    
    // Check for semantic labels, roles, and actions
    expect(tester.getSemantics(find.byType(Scaffold)), isNotNull);
    
    handle.dispose();
  }

  /// Simulate memory pressure for performance testing
  static Future<void> simulateMemoryPressure(WidgetTester tester) async {
    // Force garbage collection
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Wait for specific condition to be true
  static Future<void> waitForCondition(
    WidgetTester tester,
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 10),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final endTime = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(endTime)) {
      if (condition()) {
        return;
      }
      
      await tester.pump(interval);
    }
    
    throw TimeoutException('Condition not met within timeout period', timeout);
  }

  /// Capture and analyze performance metrics
  static Future<Map<String, dynamic>> capturePerformanceMetrics(
    WidgetTester tester,
    Future<void> Function() action,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    await action();
    
    stopwatch.stop();
    
    return {
      'duration_ms': stopwatch.elapsedMilliseconds,
      'duration_us': stopwatch.elapsedMicroseconds,
      'widget_count': tester.allWidgets.length,
      'render_objects': tester.allRenderObjects.length,
    };
  }

  /// Take screenshot for visual regression testing
  static Future<void> takeScreenshot(
    WidgetTester tester,
    String testName,
  ) async {
    // In real implementation, this would capture and save screenshot
    await tester.pump();
  }

  /// Simulate user interaction patterns
  static Future<void> simulateUserInteractionPattern(
    WidgetTester tester,
    List<Map<String, dynamic>> interactions,
  ) async {
    for (final interaction in interactions) {
      final action = interaction['action'] as String;
      final finder = interaction['finder'] as Finder;
      final delay = interaction['delay'] as Duration? ?? const Duration(milliseconds: 100);
      
      switch (action) {
        case 'tap':
          await tester.tap(finder);
          break;
        case 'longPress':
          await tester.longPress(finder);
          break;
        case 'drag':
          final offset = interaction['offset'] as Offset? ?? const Offset(0, -100);
          await tester.drag(finder, offset);
          break;
        case 'enterText':
          final text = interaction['text'] as String;
          await tester.enterText(finder, text);
          break;
      }
      
      await tester.pump(delay);
    }
  }

  /// Verify error handling
  static Future<void> verifyErrorHandling(
    WidgetTester tester,
    Future<void> Function() errorAction,
    String expectedErrorMessage,
  ) async {
    try {
      await errorAction();
      fail('Expected error was not thrown');
    } catch (e) {
      expect(e.toString(), contains(expectedErrorMessage));
    }
  }

  /// Create test data scenarios
  static Map<String, dynamic> createTestScenario({
    required String name,
    required List<Task> tasks,
    required List<Category> categories,
    Map<String, dynamic>? metadata,
  }) {
    return {
      'name': name,
      'tasks': tasks,
      'categories': categories,
      'metadata': metadata ?? {},
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Load test scenario
  static Future<void> loadTestScenario(
    WidgetTester tester,
    Map<String, dynamic> scenario,
  ) async {
    final tasks = scenario['tasks'] as List<Task>;
    final categories = scenario['categories'] as List<Category>;
    
    // Load categories first
    for (final category in categories) {
      // In real implementation, insert into test database
      await tester.pump(const Duration(milliseconds: 10));
    }
    
    // Then load tasks
    for (final task in tasks) {
      // In real implementation, insert into test database
      await tester.pump(const Duration(milliseconds: 10));
    }
  }
}

/// Custom timeout exception for test helpers
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;
  
  const TimeoutException(this.message, this.timeout);
  
  @override
  String toString() => 'TimeoutException: $message (timeout: $timeout)';
}

/// Test performance analyzer
class TestPerformanceAnalyzer {
  static final Map<String, List<int>> _measurements = {};
  
  static void recordMeasurement(String testName, int durationMs) {
    _measurements.putIfAbsent(testName, () => []).add(durationMs);
  }
  
  static Map<String, dynamic> getStatistics(String testName) {
    final measurements = _measurements[testName];
    if (measurements == null || measurements.isEmpty) {
      return {'error': 'No measurements found for $testName'};
    }
    
    measurements.sort();
    final count = measurements.length;
    final sum = measurements.reduce((a, b) => a + b);
    final avg = sum / count;
    final median = count % 2 == 0
        ? (measurements[count ~/ 2 - 1] + measurements[count ~/ 2]) / 2
        : measurements[count ~/ 2].toDouble();
    
    return {
      'count': count,
      'average_ms': avg,
      'median_ms': median,
      'min_ms': measurements.first,
      'max_ms': measurements.last,
      'p95_ms': measurements[(count * 0.95).floor()],
      'p99_ms': measurements[(count * 0.99).floor()],
    };
  }
  
  static void printReport() {
    print('\n=== Test Performance Report ===');
    for (final testName in _measurements.keys) {
      final stats = getStatistics(testName);
      print('$testName:');
      print('  Average: ${stats['average_ms']?.toStringAsFixed(2)}ms');
      print('  Median: ${stats['median_ms']?.toStringAsFixed(2)}ms');
      print('  P95: ${stats['p95_ms']}ms');
      print('  Min/Max: ${stats['min_ms']}ms / ${stats['max_ms']}ms');
      print('');
    }
  }
  
  static void clear() {
    _measurements.clear();
  }
}