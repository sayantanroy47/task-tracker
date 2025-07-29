import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:task_tracker_app/core/repositories/impl/task_repository_impl.dart';
import 'package:task_tracker_app/core/services/database_service.dart';
import 'package:task_tracker_app/shared/models/models.dart';
import '../../test_utils/fixtures.dart';

@GenerateMocks([DatabaseService])
import 'task_repository_test.mocks.dart';

void main() {
  // Setup SQLite FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TaskRepositoryImpl Tests', () {
    late TaskRepositoryImpl taskRepository;
    late MockDatabaseService mockDatabaseService;
    late DatabaseService realDatabaseService;

    setUp(() {
      mockDatabaseService = MockDatabaseService();
      realDatabaseService = DatabaseService();
    });

    tearDown(() async {
      await realDatabaseService.clearTestDatabase();
    });

    group('Task CRUD Operations', () {
      setUp(() {
        taskRepository = TaskRepositoryImpl(realDatabaseService);
      });

      test('should create task successfully', () async {
        final task = TaskFixtures.createTask(
          id: 'test-task-1',
          title: 'Test Task',
          categoryId: 'personal',
        );

        final createdTask = await taskRepository.createTask(task);

        expect(createdTask.id, task.id);
        expect(createdTask.title, task.title);
        expect(createdTask.categoryId, task.categoryId);
      });

      test('should retrieve task by ID', () async {
        final task = TaskFixtures.createTask(
          id: 'test-task-2',
          title: 'Retrieve Test',
          categoryId: 'personal',
        );

        await taskRepository.createTask(task);
        final retrievedTask = await taskRepository.getTaskById(task.id);

        expect(retrievedTask, isNotNull);
        expect(retrievedTask?.id, task.id);
        expect(retrievedTask?.title, task.title);
      });

      test('should return null for non-existent task', () async {
        final retrievedTask = await taskRepository.getTaskById('non-existent');
        expect(retrievedTask, isNull);
      });

      test('should update task successfully', () async {
        final task = TaskFixtures.createTask(
          id: 'test-task-3',
          title: 'Original Title',
          categoryId: 'personal',
        );

        await taskRepository.createTask(task);
        
        final updatedTask = task.copyWith(
          title: 'Updated Title',
          isCompleted: true,
        );

        final result = await taskRepository.updateTask(updatedTask);

        expect(result.title, 'Updated Title');
        expect(result.isCompleted, true);
        expect(result.updatedAt.isAfter(task.updatedAt), true);
      });

      test('should delete task successfully', () async {
        final task = TaskFixtures.createTask(
          id: 'test-task-4',
          title: 'Delete Test',
          categoryId: 'personal',
        );

        await taskRepository.createTask(task);
        await taskRepository.deleteTask(task.id);

        final retrievedTask = await taskRepository.getTaskById(task.id);
        expect(retrievedTask, isNull);
      });

      test('should get all tasks ordered by creation date', () async {
        final tasks = TaskFixtures.createTaskList(count: 5);
        
        for (final task in tasks) {
          await taskRepository.createTask(task);
        }

        final allTasks = await taskRepository.getAllTasks();
        
        expect(allTasks.length, 5);
        
        // Should be ordered by created_at DESC
        for (int i = 0; i < allTasks.length - 1; i++) {
          expect(
            allTasks[i].createdAt.isAfter(allTasks[i + 1].createdAt) ||
            allTasks[i].createdAt.isAtSameMomentAs(allTasks[i + 1].createdAt),
            true
          );
        }
      });
    });

    group('Task Filtering and Querying', () {
      setUp(() {
        taskRepository = TaskRepositoryImpl(realDatabaseService);
      });

      test('should get tasks by category', () async {
        final personalTasks = TaskFixtures.createTaskList(
          count: 3,
          categoryId: 'personal',
        );
        final workTasks = TaskFixtures.createTaskList(
          count: 2,
          categoryId: 'work',
        );

        for (final task in [...personalTasks, ...workTasks]) {
          await taskRepository.createTask(task);
        }

        final retrievedPersonalTasks = await taskRepository.getTasksByCategory('personal');
        final retrievedWorkTasks = await taskRepository.getTasksByCategory('work');

        expect(retrievedPersonalTasks.length, 3);
        expect(retrievedWorkTasks.length, 2);
        
        expect(retrievedPersonalTasks.every((t) => t.categoryId == 'personal'), true);
        expect(retrievedWorkTasks.every((t) => t.categoryId == 'work'), true);
      });

      test('should get tasks by date', () async {
        final today = DateTime.now();
        final tomorrow = today.add(const Duration(days: 1));
        
        final todaysTasks = TaskFixtures.createTodaysTasks(count: 3);
        final tomorrowTask = TaskFixtures.createTask(
          id: 'tomorrow-task',
          title: 'Tomorrow Task',
          dueDate: tomorrow,
          categoryId: 'personal',
        );

        for (final task in [...todaysTasks, tomorrowTask]) {
          await taskRepository.createTask(task);
        }

        final retrievedTodaysTasks = await taskRepository.getTasksByDate(today);
        final retrievedTomorrowTasks = await taskRepository.getTasksByDate(tomorrow);

        expect(retrievedTodaysTasks.length, 3);
        expect(retrievedTomorrowTasks.length, 1);
        
        expect(retrievedTodaysTasks.every((t) => t.isDueToday), true);
        expect(retrievedTomorrowTasks.every((t) => t.isDueTomorrow), true);
      });

      test('should get completed tasks', () async {
        final tasks = TaskFixtures.createTaskList(count: 5, mixCompleted: true);
        
        for (final task in tasks) {
          await taskRepository.createTask(task);
        }

        final completedTasks = await taskRepository.getCompletedTasks();
        final incompleteTasks = await taskRepository.getIncompleteTasks();

        expect(completedTasks.every((t) => t.isCompleted), true);
        expect(incompleteTasks.every((t) => !t.isCompleted), true);
        expect(completedTasks.length + incompleteTasks.length, tasks.length);
      });

      test('should get overdue tasks', () async {
        final overdueTasks = TaskFixtures.createOverdueTasks(count: 3);
        final futureTasks = [
          TaskFixtures.createTask(
            id: 'future-1',
            title: 'Future Task',
            dueDate: DateTime.now().add(const Duration(days: 1)),
            categoryId: 'personal',
          ),
        ];

        for (final task in [...overdueTasks, ...futureTasks]) {
          await taskRepository.createTask(task);
        }

        final retrievedOverdueTasks = await taskRepository.getOverdueTasks();

        expect(retrievedOverdueTasks.length, 3);
        expect(retrievedOverdueTasks.every((t) => t.isOverdue), true);
      });

      test('should search tasks by title and description', () async {
        final tasks = [
          TaskFixtures.createTask(
            id: 'search-1',
            title: 'Buy groceries',
            description: 'Milk, bread, eggs',
            categoryId: 'personal',
          ),
          TaskFixtures.createTask(
            id: 'search-2',
            title: 'Call doctor',
            description: 'Schedule appointment',
            categoryId: 'health',
          ),
          TaskFixtures.createTask(
            id: 'search-3',
            title: 'Meeting with client',
            description: 'Discuss project requirements',
            categoryId: 'work',
          ),
        ];

        for (final task in tasks) {
          await taskRepository.createTask(task);
        }

        final grocerySearchResults = await taskRepository.searchTasks('groceries');
        final doctorSearchResults = await taskRepository.searchTasks('doctor');
        final appointmentSearchResults = await taskRepository.searchTasks('appointment');

        expect(grocerySearchResults.length, 1);
        expect(grocerySearchResults.first.title, 'Buy groceries');

        expect(doctorSearchResults.length, 1);
        expect(doctorSearchResults.first.title, 'Call doctor');

        expect(appointmentSearchResults.length, 1);
        expect(appointmentSearchResults.first.description, contains('appointment'));
      });
    });

    group('Task Statistics', () {
      setUp(() {
        taskRepository = TaskRepositoryImpl(realDatabaseService);
      });

      test('should get task count by category', () async {
        final personalTasks = TaskFixtures.createTaskList(count: 3, categoryId: 'personal');
        final workTasks = TaskFixtures.createTaskList(count: 5, categoryId: 'work');

        for (final task in [...personalTasks, ...workTasks]) {
          await taskRepository.createTask(task);
        }

        final personalCount = await taskRepository.getTaskCountByCategory('personal');
        final workCount = await taskRepository.getTaskCountByCategory('work');
        final healthCount = await taskRepository.getTaskCountByCategory('health');

        expect(personalCount, 3);
        expect(workCount, 5);
        expect(healthCount, 0);
      });

      test('should get completion statistics', () async {
        final tasks = [
          ...TaskFixtures.createTaskList(count: 6, mixCompleted: false), // 6 incomplete
          ...TaskFixtures.createTaskList(count: 4, mixCompleted: false).map((t) => t.complete()), // 4 complete
        ];

        for (final task in tasks) {
          await taskRepository.createTask(task);
        }

        final stats = await taskRepository.getCompletionStats();

        expect(stats['total'], 10);
        expect(stats['completed'], 4);
        expect(stats['incomplete'], 6);
        expect(stats['completionRate'], closeTo(0.4, 0.01));
      });

      test('should get tasks by priority', () async {
        final lowPriorityTasks = List.generate(2, (i) => 
          TaskFixtures.createTask(
            id: 'low-$i',
            title: 'Low Priority $i',
            priority: TaskPriority.low,
            categoryId: 'personal',
          ),
        );

        final highPriorityTasks = List.generate(3, (i) => 
          TaskFixtures.createTask(
            id: 'high-$i',
            title: 'High Priority $i',
            priority: TaskPriority.high,
            categoryId: 'personal',
          ),
        );

        for (final task in [...lowPriorityTasks, ...highPriorityTasks]) {
          await taskRepository.createTask(task);
        }

        final lowTasks = await taskRepository.getTasksByPriority(TaskPriority.low);
        final highTasks = await taskRepository.getTasksByPriority(TaskPriority.high);

        expect(lowTasks.length, 2);
        expect(highTasks.length, 3);
        expect(lowTasks.every((t) => t.priority == TaskPriority.low), true);
        expect(highTasks.every((t) => t.priority == TaskPriority.high), true);
      });
    });

    group('Task Streams and Real-time Updates', () {
      setUp(() {
        taskRepository = TaskRepositoryImpl(realDatabaseService);
      });

      test('should emit updated tasks when task is created', () async {
        final streamSubscription = taskRepository.taskStream.listen(expectAsync1((tasks) {
          expect(tasks.length, greaterThan(0));
          expect(tasks.any((t) => t.title == 'Stream Test Task'), true);
        }));

        await taskRepository.createTask(TaskFixtures.createTask(
          id: 'stream-test',
          title: 'Stream Test Task',
          categoryId: 'personal',
        ));

        await streamSubscription.cancel();
      });

      test('should emit updated tasks when task is updated', () async {
        final task = TaskFixtures.createTask(
          id: 'stream-update-test',
          title: 'Original Title',
          categoryId: 'personal',
        );

        await taskRepository.createTask(task);

        final streamSubscription = taskRepository.taskStream.listen(expectAsync1((tasks) {
          final updatedTask = tasks.firstWhere((t) => t.id == task.id);
          expect(updatedTask.title, 'Updated Title');
        }));

        await taskRepository.updateTask(task.copyWith(title: 'Updated Title'));

        await streamSubscription.cancel();
      });
    });

    group('Error Handling', () {
      setUp(() {
        taskRepository = TaskRepositoryImpl(mockDatabaseService);
      });

      test('should handle database errors gracefully', () async {
        when(mockDatabaseService.database).thenThrow(Exception('Database connection failed'));

        expect(
          () => taskRepository.getAllTasks(),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle invalid task data', () async {
        final invalidTask = Task(
          id: '', // Invalid empty ID
          title: '',
          categoryId: 'non-existent-category',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Using real database service to test constraint violations
        taskRepository = TaskRepositoryImpl(realDatabaseService);

        expect(
          () => taskRepository.createTask(invalidTask),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Performance Tests', () {
      setUp(() {
        taskRepository = TaskRepositoryImpl(realDatabaseService);
      });

      test('should handle bulk operations efficiently', () async {
        final tasks = List.generate(100, (i) => TaskFixtures.createTask(
          id: 'bulk-$i',
          title: 'Bulk Task $i',
          categoryId: 'personal',
        ));

        final stopwatch = Stopwatch()..start();

        for (final task in tasks) {
          await taskRepository.createTask(task);
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should complete in under 5 seconds

        final allTasks = await taskRepository.getAllTasks();
        expect(allTasks.length, 100);
      });

      test('should execute queries with reasonable performance', () async {
        // Create test data
        final tasks = List.generate(500, (i) => TaskFixtures.createTask(
          id: 'perf-$i',
          title: 'Performance Task $i',
          categoryId: i % 6 == 0 ? 'personal' : 'work',
        ));

        for (final task in tasks) {
          await taskRepository.createTask(task);
        }

        final stopwatch = Stopwatch()..start();

        // Test various query operations
        await taskRepository.getAllTasks();
        await taskRepository.getTasksByCategory('personal');
        await taskRepository.getCompletedTasks();
        await taskRepository.searchTasks('Performance');

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // All queries should complete in under 1 second
      });
    });
  });
}