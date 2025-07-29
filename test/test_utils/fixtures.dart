import 'package:task_tracker_app/shared/models/models.dart';
import 'package:uuid/uuid.dart';

/// Test data fixtures for consistent testing across the application
/// Provides realistic test data that mimics real user scenarios
class TaskFixtures {
  static const _uuid = Uuid();

  /// Create a basic task with customizable properties
  static Task createTask({
    String? id,
    String title = 'Test Task',
    String? description,
    String categoryId = 'cat-1',
    DateTime? dueDate,
    DateTime? dueTime,
    TaskPriority priority = TaskPriority.medium,
    bool isCompleted = false,
    TaskSource source = TaskSource.manual,
    bool hasReminder = false,
    List<ReminderInterval> reminderIntervals = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return Task(
      id: id ?? _uuid.v4(),
      title: title,
      description: description,
      categoryId: categoryId,
      dueDate: dueDate,
      dueTime: dueTime,
      priority: priority,
      isCompleted: isCompleted,
      source: source,
      hasReminder: hasReminder,
      reminderIntervals: reminderIntervals,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  /// Create a list of tasks for testing pagination and bulk operations
  static List<Task> createTaskList({
    int count = 5,
    String categoryId = 'cat-1',
    bool mixCompleted = true,
  }) {
    return List.generate(count, (index) {
      final isCompleted = mixCompleted ? index % 3 == 0 : false;
      return createTask(
        id: 'task-${index + 1}',
        title: 'Task ${index + 1}',
        description: 'Description for task ${index + 1}',
        categoryId: categoryId,
        dueDate: DateTime.now().add(Duration(days: index)),
        priority: TaskPriority.values[index % TaskPriority.values.length],
        isCompleted: isCompleted,
        source: TaskSource.values[index % TaskSource.values.length],
      );
    });
  }

  /// Create overdue tasks for testing reminder functionality
  static List<Task> createOverdueTasks({int count = 3}) {
    return List.generate(count, (index) => createTask(
      id: 'overdue-${index + 1}',
      title: 'Overdue Task ${index + 1}',
      dueDate: DateTime.now().subtract(Duration(days: index + 1)),
      isCompleted: false,
    ));
  }

  /// Create tasks due today for testing today's view
  static List<Task> createTodaysTasks({int count = 3}) {
    final today = DateTime.now();
    return List.generate(count, (index) => createTask(
      id: 'today-${index + 1}',
      title: 'Today Task ${index + 1}',
      dueDate: today,
      dueTime: DateTime(today.year, today.month, today.day, 9 + index, 0),
    ));
  }

  /// Create tasks with voice input source for testing voice features
  static List<Task> createVoiceTasks({int count = 3}) {
    return List.generate(count, (index) => createTask(
      id: 'voice-${index + 1}',
      title: 'Voice Task ${index + 1}',
      description: 'Created via voice input',
      source: TaskSource.voice,
      hasReminder: true,
      reminderIntervals: [ReminderInterval.oneHour],
    ));
  }

  /// Create tasks with chat source for testing chat integration
  static List<Task> createChatTasks({int count = 3}) {
    return List.generate(count, (index) => createTask(
      id: 'chat-${index + 1}',
      title: 'Chat Task ${index + 1}',
      description: 'Extracted from chat message',
      source: TaskSource.chat,
    ));
  }
}

/// Category test fixtures
class CategoryFixtures {
  /// Create a basic category with customizable properties
  static Category createCategory({
    String? id,
    String name = 'Test Category',
    String description = 'Test category description',
    int color = 0xFF2196F3,
    String icon = 'category',
    bool isDefault = false,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? 'cat-test',
      name: name,
      description: description,
      color: color,
      icon: icon,
      isDefault: isDefault,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Create the default system categories
  static List<Category> createDefaultCategories() {
    return [
      createCategory(
        id: 'cat-personal',
        name: 'Personal',
        description: 'Personal tasks and goals',
        color: 0xFF2196F3,
        icon: 'person',
        isDefault: true,
      ),
      createCategory(
        id: 'cat-work',
        name: 'Work',
        description: 'Work-related tasks',
        color: 0xFF4CAF50,
        icon: 'work',
        isDefault: true,
      ),
      createCategory(
        id: 'cat-household',
        name: 'Household',
        description: 'Home and chores',
        color: 0xFFFF9800,
        icon: 'home',
        isDefault: true,
      ),
      createCategory(
        id: 'cat-health',
        name: 'Health',
        description: 'Health and fitness',
        color: 0xFFE91E63,
        icon: 'health',
        isDefault: true,
      ),
      createCategory(
        id: 'cat-finance',
        name: 'Finance',
        description: 'Financial tasks and bills',
        color: 0xFF9C27B0,
        icon: 'money',
        isDefault: true,
      ),
      createCategory(
        id: 'cat-family',
        name: 'Family',
        description: 'Family-related tasks',
        color: 0xFFFF5722,
        icon: 'family',
        isDefault: true,
      ),
    ];
  }

  /// Create a list of custom categories for testing
  static List<Category> createCustomCategories({int count = 3}) {
    return List.generate(count, (index) => createCategory(
      id: 'custom-${index + 1}',
      name: 'Custom Category ${index + 1}',
      description: 'Custom category description ${index + 1}',
      color: 0xFF000000 + (index * 0x111111),
      isDefault: false,
    ));
  }
}

/// Notification test fixtures
class NotificationFixtures {
  /// Create a basic notification
  static TaskNotification createNotification({
    String? id,
    String taskId = 'task-1',
    DateTime? scheduledTime,
    NotificationType type = NotificationType.reminder,
    String? title,
    String? body,
    bool sent = false,
    DateTime? createdAt,
  }) {
    final now = DateTime.now();
    return TaskNotification(
      id: id ?? 'notif-test',
      taskId: taskId,
      scheduledTime: scheduledTime ?? now.add(const Duration(hours: 1)),
      type: type,
      title: title ?? 'Test Notification',
      body: body ?? 'Test notification body',
      sent: sent,
      createdAt: createdAt ?? now,
    );
  }

  /// Create multiple notifications for a task
  static List<TaskNotification> createTaskNotifications({
    String taskId = 'task-1',
    int count = 3,
  }) {
    return List.generate(count, (index) => createNotification(
      id: 'notif-$taskId-${index + 1}',
      taskId: taskId,
      scheduledTime: DateTime.now().add(Duration(hours: index + 1)),
      type: NotificationType.values[index % NotificationType.values.length],
    ));
  }
}

/// Voice input test fixtures for testing voice processing
class VoiceFixtures {
  /// Sample voice inputs that should be parsed correctly
  static const List<String> sampleVoiceInputs = [
    'Remind me to buy groceries tomorrow at 3 PM',
    'Call mom this Friday at 5 o\'clock',
    'Doctor appointment next Tuesday at 10:30 AM',
    'Pay rent on the first of next month',
    'Pick up kids from school today at 3:15',
    'Meeting with John at 2 PM next Wednesday',
    'Submit report by end of week',
    'Take medication every morning at 8 AM',
    'Workout session tonight at 7',
    'Book flight for vacation next month',
  ];

  /// Create parsed voice input result for testing
  static Map<String, dynamic> createParsedVoiceInput({
    String originalText = 'Buy groceries tomorrow at 3 PM',
    String taskTitle = 'Buy groceries',
    DateTime? parsedDate,
    DateTime? parsedTime,
    String? suggestedCategory = 'Household',
    double confidence = 0.9,
  }) {
    return {
      'originalText': originalText,
      'taskTitle': taskTitle,
      'parsedDate': parsedDate ?? DateTime.now().add(const Duration(days: 1)),
      'parsedTime': parsedTime,
      'suggestedCategory': suggestedCategory,
      'confidence': confidence,
    };
  }

  /// Create voice inputs with challenging parsing scenarios
  static List<String> getChallengingVoiceInputs() {
    return [
      'Um, remind me to, uh, call the dentist tomorrow',
      'Set a reminder for next week sometime to clean the garage',
      'I need to remember to buy milk when I go shopping',
      'Meeting at two... no, make that three PM on Friday',
      'Remind me to take my medicine in an hour',
    ];
  }
}

/// Test data combinations for complex scenarios
class TestScenarios {
  /// Create a realistic user scenario with mixed task states
  static Map<String, dynamic> createUserScenario() {
    final categories = CategoryFixtures.createDefaultCategories();
    final tasks = <Task>[];
    
    // Add some completed tasks
    tasks.addAll(TaskFixtures.createTaskList(
      count: 5,
      categoryId: categories.first.id,
      mixCompleted: true,
    ));
    
    // Add overdue tasks
    tasks.addAll(TaskFixtures.createOverdueTasks(count: 2));
    
    // Add today's tasks
    tasks.addAll(TaskFixtures.createTodaysTasks(count: 3));
    
    // Add voice tasks
    tasks.addAll(TaskFixtures.createVoiceTasks(count: 2));
    
    return {
      'categories': categories,
      'tasks': tasks,
      'totalTasks': tasks.length,
      'completedTasks': tasks.where((t) => t.isCompleted).length,
      'overdueTasks': tasks.where((t) => t.isOverdue).length,
      'todaysTasks': tasks.where((t) => t.isDueToday).length,
    };
  }

  /// Create edge case scenarios for robust testing
  static Map<String, dynamic> createEdgeCaseScenario() {
    return {
      'emptyTitle': TaskFixtures.createTask(title: ''),
      'veryLongTitle': TaskFixtures.createTask(
        title: 'A' * 1000, // Very long title
      ),
      'specialCharacters': TaskFixtures.createTask(
        title: '!@#\$%^&*()_+{}|:<>?[]\\;\'\",./',
        description: 'Task with special characters: 🎯📝✅',
      ),
      'pastDueDate': TaskFixtures.createTask(
        dueDate: DateTime(1900, 1, 1),
      ),
      'futureDueDate': TaskFixtures.createTask(
        dueDate: DateTime(2100, 12, 31),
      ),
      'nullValues': TaskFixtures.createTask(
        description: null,
        dueDate: null,
        dueTime: null,
      ),
    };
  }
}