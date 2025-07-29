import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../shared/models/models.dart';
import '../task_repository.dart';
import '../../services/database_service.dart';

/// Concrete implementation of TaskRepository using SQLite
class TaskRepositoryImpl implements TaskRepository {
  final DatabaseService _databaseService;
  final StreamController<List<Task>> _taskStreamController = StreamController<List<Task>>.broadcast();

  TaskRepositoryImpl(this._databaseService);

  Future<Database> get _database => _databaseService.database;

  @override
  Future<List<Task>> getAllTasks() async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  @override
  Future<List<Task>> getTasksByCategory(String categoryId) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  @override
  Future<List<Task>> getTasksByDate(DateTime date) async {
    final db = await _database;
    final dateString = date.toIso8601String().split('T')[0]; // Get date part only
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'due_date LIKE ?',
      whereArgs: ['$dateString%'],
      orderBy: 'due_time ASC, created_at DESC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  @override
  Future<List<Task>> getTasksByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _database;
    final startString = startDate.toIso8601String().split('T')[0];
    final endString = endDate.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'due_date >= ? AND due_date <= ?',
      whereArgs: [startString, endString],
      orderBy: 'due_date ASC, due_time ASC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  @override
  Future<List<Task>> getCompletedTasks() async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'completed = ?',
      whereArgs: [1],
      orderBy: 'updated_at DESC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  @override
  Future<List<Task>> getPendingTasks() async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'completed = ?',
      whereArgs: [0],
      orderBy: 'due_date ASC, due_time ASC, created_at DESC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  @override
  Future<List<Task>> getOverdueTasks() async {
    final db = await _database;
    final now = DateTime.now();
    final nowString = now.toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM tasks 
      WHERE completed = 0 
      AND due_date IS NOT NULL 
      AND (
        due_date < ? 
        OR (due_date = ? AND due_time IS NOT NULL AND due_time < ?)
      )
      ORDER BY due_date ASC, due_time ASC
    ''', [
      nowString.split('T')[0],
      nowString.split('T')[0],
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    ]);
    
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  @override
  Future<Task?> getTaskById(String id) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  @override
  Future<List<Task>> searchTasks(String query) async {
    final db = await _database;
    
    // Use FTS5 for full-text search when available
    try {
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT t.* FROM tasks t
        INNER JOIN tasks_fts fts ON t.id = fts.rowid
        WHERE tasks_fts MATCH ?
        ORDER BY rank, t.created_at DESC
      ''', [query]);
      
      return maps.map((map) => Task.fromMap(map)).toList();
    } catch (e) {
      // Fall back to LIKE search if FTS fails
      debugPrint('FTS search failed, falling back to LIKE: $e');
      final searchPattern = '%${query.toLowerCase()}%';
      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        where: 'LOWER(title) LIKE ? OR LOWER(description) LIKE ?',
        whereArgs: [searchPattern, searchPattern],
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => Task.fromMap(map)).toList();
    }
  }

  /// Enhanced search with pagination and filtering
  Future<List<Task>> searchTasksPaginated({
    String? query,
    List<String>? categoryIds,
    List<TaskPriority>? priorities,
    List<TaskSource>? sources,
    bool? isCompleted,
    DateTime? startDate,
    DateTime? endDate,
    String orderBy = 'created_at DESC',
    int? limit,
    int? offset,
  }) async {
    final db = await _database;
    
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];
    
    // Text search condition
    String fromClause = 'tasks t';
    if (query != null && query.trim().isNotEmpty) {
      try {
        // Use FTS5 for text search
        fromClause = 'tasks t INNER JOIN tasks_fts fts ON t.id = fts.rowid';
        whereConditions.add('tasks_fts MATCH ?');
        whereArgs.add(query);
      } catch (e) {
        // Fall back to LIKE search
        whereConditions.add('(LOWER(t.title) LIKE ? OR LOWER(t.description) LIKE ?)');
        final searchPattern = '%${query.toLowerCase()}%';
        whereArgs.addAll([searchPattern, searchPattern]);
      }
    }
    
    // Category filter
    if (categoryIds != null && categoryIds.isNotEmpty) {
      final placeholders = categoryIds.map((_) => '?').join(',');
      whereConditions.add('t.category_id IN ($placeholders)');
      whereArgs.addAll(categoryIds);
    }
    
    // Priority filter
    if (priorities != null && priorities.isNotEmpty) {
      final placeholders = priorities.map((_) => '?').join(',');
      whereConditions.add('t.priority IN ($placeholders)');
      whereArgs.addAll(priorities.map((p) => p.index));
    }
    
    // Source filter
    if (sources != null && sources.isNotEmpty) {
      final placeholders = sources.map((_) => '?').join(',');
      whereConditions.add('t.source IN ($placeholders)');
      whereArgs.addAll(sources.map((s) => s.name));
    }
    
    // Completion status filter
    if (isCompleted != null) {
      whereConditions.add('t.completed = ?');
      whereArgs.add(isCompleted ? 1 : 0);
    }
    
    // Date range filter
    if (startDate != null) {
      whereConditions.add('t.due_date >= ?');
      whereArgs.add(startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      whereConditions.add('t.due_date <= ?');
      whereArgs.add(endDate.toIso8601String().split('T')[0]);
    }
    
    // Build query
    final whereClause = whereConditions.isNotEmpty 
        ? 'WHERE ${whereConditions.join(' AND ')}' 
        : '';
    
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final offsetClause = offset != null ? 'OFFSET $offset' : '';
    
    final sql = '''
      SELECT t.* FROM $fromClause
      $whereClause
      ORDER BY $orderBy
      $limitClause $offsetClause
    ''';
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, whereArgs);
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  @override
  Future<String> createTask(Task task) async {
    final db = await _database;
    final taskData = task.toMap();
    
    await db.insert('tasks', taskData);
    _notifyTasksChanged();
    return task.id;
  }

  @override
  Future<void> updateTask(Task task) async {
    final db = await _database;
    final taskData = task.toMap();
    
    await db.update(
      'tasks',
      taskData,
      where: 'id = ?',
      whereArgs: [task.id],
    );
    _notifyTasksChanged();
  }

  @override
  Future<void> deleteTask(String id) async {
    final db = await _database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    _notifyTasksChanged();
  }

  @override
  Future<void> toggleTaskCompletion(String id) async {
    final task = await getTaskById(id);
    if (task != null) {
      final updatedTask = task.copyWith(
        isCompleted: !task.isCompleted,
        updatedAt: DateTime.now(),
      );
      await updateTask(updatedTask);
    }
  }

  @override
  Future<void> markTaskCompleted(String id) async {
    final task = await getTaskById(id);
    if (task != null && !task.isCompleted) {
      final updatedTask = task.copyWith(
        isCompleted: true,
        updatedAt: DateTime.now(),
      );
      await updateTask(updatedTask);
    }
  }

  @override
  Future<void> bulkUpdateTasks(List<Task> tasks) async {
    final db = await _database;
    final batch = db.batch();
    
    for (final task in tasks) {
      batch.update(
        'tasks',
        task.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
    }
    
    await batch.commit();
    _notifyTasksChanged();
  }

  @override
  Future<void> bulkDeleteTasks(List<String> taskIds) async {
    final db = await _database;
    final batch = db.batch();
    
    for (final id in taskIds) {
      batch.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    
    await batch.commit();
    _notifyTasksChanged();
  }

  @override
  Future<Map<String, int>> getTaskCountByCategory() async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT category_id, COUNT(*) as count
      FROM tasks
      GROUP BY category_id
    ''');
    
    final result = <String, int>{};
    for (final map in maps) {
      result[map['category_id'] as String] = map['count'] as int;
    }
    return result;
  }

  @override
  Future<Map<String, int>> getTaskStatistics() async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_tasks,
        SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) as completed_tasks,
        SUM(CASE WHEN completed = 0 THEN 1 ELSE 0 END) as pending_tasks,
        SUM(CASE WHEN source = 'voice' THEN 1 ELSE 0 END) as voice_tasks,
        SUM(CASE WHEN source = 'chat' THEN 1 ELSE 0 END) as chat_tasks,
        SUM(CASE WHEN source = 'manual' THEN 1 ELSE 0 END) as manual_tasks
      FROM tasks
    ''');
    
    final result = maps.first;
    return {
      'total': result['total_tasks'] as int,
      'completed': result['completed_tasks'] as int,
      'pending': result['pending_tasks'] as int,
      'voice': result['voice_tasks'] as int,
      'chat': result['chat_tasks'] as int,
      'manual': result['manual_tasks'] as int,
    };
  }

  @override
  Stream<List<Task>> watchAllTasks() {
    // Initial load
    getAllTasks().then((tasks) => _taskStreamController.add(tasks));
    return _taskStreamController.stream;
  }

  @override
  Stream<List<Task>> watchTasksByDate(DateTime date) {
    return watchAllTasks().asyncMap((_) => getTasksByDate(date));
  }

  @override
  Stream<List<Task>> watchTasksByCategory(String categoryId) {
    return watchAllTasks().asyncMap((_) => getTasksByCategory(categoryId));
  }

  @override
  Stream<List<Task>> watchPendingTasks() {
    return watchAllTasks().asyncMap((_) => getPendingTasks());
  }

  void _notifyTasksChanged() {
    getAllTasks().then((tasks) => _taskStreamController.add(tasks));
  }

  void dispose() {
    _taskStreamController.close();
  }
}