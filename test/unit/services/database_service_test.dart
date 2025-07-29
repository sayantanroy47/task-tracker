import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:task_tracker_app/core/services/database_service.dart';
import 'package:task_tracker_app/shared/models/models.dart';
import '../../test_utils/fixtures.dart';

void main() {
  // Setup SQLite FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseService Tests', () {
    late DatabaseService databaseService;

    setUp(() {
      databaseService = DatabaseService();
    });

    tearDown(() async {
      // Clean up test database
      final db = await databaseService.database;
      await db.close();
      await databaseService.clearTestDatabase();
    });

    group('Database Initialization', () {
      test('should initialize database successfully', () async {
        final db = await databaseService.database;
        expect(db, isNotNull);
        expect(db.isOpen, true);
      });

      test('should create all required tables', () async {
        final db = await databaseService.database;
        
        // Check if tables exist
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table';"
        );
        
        final tableNames = tables.map((t) => t['name'] as String).toSet();
        expect(tableNames, contains('categories'));
        expect(tableNames, contains('tasks'));
        expect(tableNames, contains('notifications'));
      });

      test('should insert default categories on first run', () async {
        final db = await databaseService.database;
        
        final categories = await db.query('categories');
        expect(categories.length, 6); // 6 default categories
        
        final categoryNames = categories.map((c) => c['name']).toSet();
        expect(categoryNames, contains('Personal'));
        expect(categoryNames, contains('Work'));
        expect(categoryNames, contains('Household'));
        expect(categoryNames, contains('Health'));
        expect(categoryNames, contains('Finance'));
        expect(categoryNames, contains('Family'));
      });

      test('should enable foreign key constraints', () async {
        final db = await databaseService.database;
        
        final result = await db.rawQuery('PRAGMA foreign_keys');
        expect(result.first['foreign_keys'], 1);
      });
    });

    group('Database Operations', () {
      test('should support basic CRUD operations on tasks', () async {
        final db = await databaseService.database;
        
        // Create
        final taskMap = TaskFixtures.createTask(
          id: 'test-task',
          title: 'Test Task',
          categoryId: 'personal',
        ).toMap();
        
        await db.insert('tasks', taskMap);
        
        // Read
        final tasks = await db.query('tasks', where: 'id = ?', whereArgs: ['test-task']);
        expect(tasks.length, 1);
        expect(tasks.first['title'], 'Test Task');
        
        // Update
        await db.update(
          'tasks',
          {'title': 'Updated Task'},
          where: 'id = ?',
          whereArgs: ['test-task'],
        );
        
        final updatedTasks = await db.query('tasks', where: 'id = ?', whereArgs: ['test-task']);
        expect(updatedTasks.first['title'], 'Updated Task');
        
        // Delete
        await db.delete('tasks', where: 'id = ?', whereArgs: ['test-task']);
        final deletedTasks = await db.query('tasks', where: 'id = ?', whereArgs: ['test-task']);
        expect(deletedTasks.length, 0);
      });

      test('should enforce foreign key constraints', () async {
        final db = await databaseService.database;
        
        // Try to insert task with non-existent category
        final taskMap = TaskFixtures.createTask(
          id: 'test-task',
          title: 'Test Task',
          categoryId: 'non-existent-category',
        ).toMap();
        
        expect(
          () => db.insert('tasks', taskMap),
          throwsA(isA<DatabaseException>()),
        );
      });

      test('should handle database transactions', () async {
        final db = await databaseService.database;
        
        await db.transaction((txn) async {
          final taskMap1 = TaskFixtures.createTask(
            id: 'task-1',
            title: 'Task 1',
            categoryId: 'personal',
          ).toMap();
          
          final taskMap2 = TaskFixtures.createTask(
            id: 'task-2',
            title: 'Task 2',
            categoryId: 'personal',
          ).toMap();
          
          await txn.insert('tasks', taskMap1);
          await txn.insert('tasks', taskMap2);
        });
        
        final tasks = await db.query('tasks');
        expect(tasks.length, 2);
      });

      test('should rollback transaction on error', () async {
        final db = await databaseService.database;
        
        try {
          await db.transaction((txn) async {
            final taskMap = TaskFixtures.createTask(
              id: 'task-1',
              title: 'Task 1',
              categoryId: 'personal',
            ).toMap();
            
            await txn.insert('tasks', taskMap);
            
            // This should fail due to foreign key constraint
            final invalidTaskMap = TaskFixtures.createTask(
              id: 'task-2',
              title: 'Task 2',
              categoryId: 'invalid-category',
            ).toMap();
            
            await txn.insert('tasks', invalidTaskMap);
          });
        } catch (e) {
          // Expected to fail
        }
        
        // No tasks should be inserted due to rollback
        final tasks = await db.query('tasks');
        expect(tasks.length, 0);
      });
    });

    group('Database Schema', () {
      test('should have correct tasks table schema', () async {
        final db = await databaseService.database;
        
        final schema = await db.rawQuery('PRAGMA table_info(tasks)');
        final columnNames = schema.map((c) => c['name'] as String).toSet();
        
        expect(columnNames, contains('id'));
        expect(columnNames, contains('title'));
        expect(columnNames, contains('description'));
        expect(columnNames, contains('category_id'));
        expect(columnNames, contains('due_date'));
        expect(columnNames, contains('due_time'));
        expect(columnNames, contains('priority'));
        expect(columnNames, contains('completed'));
        expect(columnNames, contains('created_at'));
        expect(columnNames, contains('updated_at'));
        expect(columnNames, contains('source'));
      });

      test('should have correct categories table schema', () async {
        final db = await databaseService.database;
        
        final schema = await db.rawQuery('PRAGMA table_info(categories)');
        final columnNames = schema.map((c) => c['name'] as String).toSet();
        
        expect(columnNames, contains('id'));
        expect(columnNames, contains('name'));
        expect(columnNames, contains('icon'));
        expect(columnNames, contains('color'));
        expect(columnNames, contains('isSystem'));
        expect(columnNames, contains('createdAt'));
      });

      test('should have correct notifications table schema', () async {
        final db = await databaseService.database;
        
        final schema = await db.rawQuery('PRAGMA table_info(notifications)');
        final columnNames = schema.map((c) => c['name'] as String).toSet();
        
        expect(columnNames, contains('id'));
        expect(columnNames, contains('task_id'));
        expect(columnNames, contains('scheduled_time'));
        expect(columnNames, contains('type'));
        expect(columnNames, contains('title'));
        expect(columnNames, contains('body'));
        expect(columnNames, contains('sent'));
        expect(columnNames, contains('created_at'));
      });
    });

    group('Database Performance', () {
      test('should handle large number of records efficiently', () async {
        final db = await databaseService.database;
        final stopwatch = Stopwatch()..start();
        
        // Insert 1000 tasks
        await db.transaction((txn) async {
          for (int i = 0; i < 1000; i++) {
            final taskMap = TaskFixtures.createTask(
              id: 'task-$i',
              title: 'Task $i',
              categoryId: 'personal',
            ).toMap();
            
            await txn.insert('tasks', taskMap);
          }
        });
        
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should complete in under 5 seconds
        
        // Verify all tasks were inserted
        final tasks = await db.query('tasks');
        expect(tasks.length, 1000);
      });

      test('should execute queries efficiently with indexes', () async {
        final db = await databaseService.database;
        
        // Insert test data
        await db.transaction((txn) async {
          for (int i = 0; i < 100; i++) {
            final taskMap = TaskFixtures.createTask(
              id: 'task-$i',
              title: 'Task $i',
              categoryId: i % 2 == 0 ? 'personal' : 'work',
            ).toMap();
            
            await txn.insert('tasks', taskMap);
          }
        });
        
        final stopwatch = Stopwatch()..start();
        
        // Query by category (should use index)
        final personalTasks = await db.query(
          'tasks',
          where: 'category_id = ?',
          whereArgs: ['personal'],
        );
        
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be very fast
        expect(personalTasks.length, 50);
      });
    });

    group('Database Error Handling', () {
      test('should handle database connection errors gracefully', () async {
        // This test simulates database connection issues
        final corruptDb = DatabaseService();
        
        // Close the database to simulate connection issues
        final db = await corruptDb.database;
        await db.close();
        
        // Attempting to use closed database should handle error gracefully
        expect(
          () => db.query('tasks'),
          throwsA(isA<DatabaseException>()),
        );
      });

      test('should handle invalid SQL queries', () async {
        final db = await databaseService.database;
        
        expect(
          () => db.rawQuery('INVALID SQL SYNTAX'),
          throwsA(isA<DatabaseException>()),
        );
      });

      test('should handle constraint violations', () async {
        final db = await databaseService.database;
        
        final taskMap = TaskFixtures.createTask(
          id: 'duplicate-id',
          title: 'Task 1',
          categoryId: 'personal',
        ).toMap();
        
        // Insert first task
        await db.insert('tasks', taskMap);
        
        // Try to insert duplicate ID
        expect(
          () => db.insert('tasks', taskMap),
          throwsA(isA<DatabaseException>()),
        );
      });
    });

    group('Database Cleanup', () {
      test('should clear database for testing', () async {
        final db = await databaseService.database;
        
        // Insert test data
        final taskMap = TaskFixtures.createTask(
          id: 'test-task',
          title: 'Test Task',
          categoryId: 'personal',
        ).toMap();
        
        await db.insert('tasks', taskMap);
        
        // Verify data exists
        final tasksBeforeCleanup = await db.query('tasks');
        expect(tasksBeforeCleanup.length, 1);
        
        // Clear database
        await databaseService.clearTestDatabase();
        
        // Verify data is cleared but tables still exist
        final tasksAfterCleanup = await db.query('tasks');
        expect(tasksAfterCleanup.length, 0);
        
        // Categories should be reset to defaults
        final categories = await db.query('categories');
        expect(categories.length, 6); // Default categories restored
      });

      test('should handle database recreation', () async {
        final db1 = await databaseService.database;
        await db1.close();
        
        // Get new database instance
        final db2 = await databaseService.database;
        expect(db2.isOpen, true);
        
        // Should have default data
        final categories = await db2.query('categories');
        expect(categories.length, 6);
      });
    });
  });
}