import 'dart:async';
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
    return maps.map((map) => Task.fromJson(map)).toList();
  }

  @override
  Future<List<Task>> getTasksByCategory(int categoryId) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Task.fromJson(map)).toList();
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
    return maps.map((map) => Task.fromJson(map)).toList();
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
    return maps.map((map) => Task.fromJson(map)).toList();
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
    return maps.map((map) => Task.fromJson(map)).toList();
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
    return maps.map((map) => Task.fromJson(map)).toList();
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
    
    return maps.map((map) => Task.fromJson(map)).toList();
  }

  @override
  Future<Task?> getTaskById(int id) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Task.fromJson(maps.first);
  }

  @override
  Future<List<Task>> searchTasks(String query) async {
    final db = await _database;
    final searchPattern = '%${query.toLowerCase()}%';
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'LOWER(title) LIKE ? OR LOWER(description) LIKE ?',
      whereArgs: [searchPattern, searchPattern],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Task.fromJson(map)).toList();
  }

  @override
  Future<int> createTask(Task task) async {
    final db = await _database;
    final taskData = task.toJson();
    taskData.remove('id'); // Remove id for auto-increment
    
    final id = await db.insert('tasks', taskData);
    _notifyTasksChanged();
    return id;
  }

  @override
  Future<void> updateTask(Task task) async {
    final db = await _database;
    final taskData = task.toJson();
    
    await db.update(
      'tasks',
      taskData,
      where: 'id = ?',
      whereArgs: [task.id],
    );
    _notifyTasksChanged();
  }

  @override
  Future<void> deleteTask(int id) async {
    final db = await _database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    _notifyTasksChanged();
  }

  @override
  Future<void> toggleTaskCompletion(int id) async {
    final task = await getTaskById(id);
    if (task != null) {
      final updatedTask = task.copyWith(
        completed: !task.completed,
        updatedAt: DateTime.now(),
      );
      await updateTask(updatedTask);
    }
  }

  @override
  Future<void> markTaskCompleted(int id) async {
    final task = await getTaskById(id);
    if (task != null && !task.completed) {
      final updatedTask = task.copyWith(
        completed: true,
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
        task.toJson(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
    }
    
    await batch.commit();
    _notifyTasksChanged();
  }

  @override
  Future<void> bulkDeleteTasks(List<int> taskIds) async {
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
  Future<Map<int, int>> getTaskCountByCategory() async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT category_id, COUNT(*) as count
      FROM tasks
      GROUP BY category_id
    ''');
    
    final result = <int, int>{};
    for (final map in maps) {
      result[map['category_id'] as int] = map['count'] as int;
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
  Stream<List<Task>> watchTasksByCategory(int categoryId) {
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