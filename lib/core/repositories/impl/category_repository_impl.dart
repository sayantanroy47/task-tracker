import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../../shared/models/models.dart';
import '../category_repository.dart';
import '../../services/database_service.dart';

/// Concrete implementation of CategoryRepository using SQLite
class CategoryRepositoryImpl implements CategoryRepository {
  final DatabaseService _databaseService;
  final StreamController<List<Category>> _categoryStreamController = StreamController<List<Category>>.broadcast();

  CategoryRepositoryImpl(this._databaseService);

  Future<Database> get _database => _databaseService.database;

  @override
  Future<List<Category>> getAllCategories() async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      orderBy: 'is_system DESC, name ASC',
    );
    return maps.map((map) => Category.fromJson(map)).toList();
  }

  @override
  Future<List<Category>> getSystemCategories() async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'is_system = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Category.fromJson(map)).toList();
  }

  @override
  Future<List<Category>> getUserCategories() async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'is_system = ?',
      whereArgs: [0],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Category.fromJson(map)).toList();
  }

  @override
  Future<Category?> getCategoryById(int id) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Category.fromJson(maps.first);
  }

  @override
  Future<Category?> getCategoryByName(String name) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'LOWER(name) = ?',
      whereArgs: [name.toLowerCase()],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Category.fromJson(maps.first);
  }

  @override
  Future<int> createCategory(Category category) async {
    final db = await _database;
    final categoryData = category.toJson();
    categoryData.remove('id'); // Remove id for auto-increment
    
    final id = await db.insert('categories', categoryData);
    _notifyCategoriesChanged();
    return id;
  }

  @override
  Future<void> updateCategory(Category category) async {
    final db = await _database;
    final categoryData = category.toJson();
    
    await db.update(
      'categories',
      categoryData,
      where: 'id = ?',
      whereArgs: [category.id],
    );
    _notifyCategoriesChanged();
  }

  @override
  Future<void> deleteCategory(int id) async {
    final category = await getCategoryById(id);
    if (category == null) return;
    
    // Prevent deletion of system categories
    if (category.isSystem) {
      throw Exception('Cannot delete system category');
    }
    
    // Check if category has tasks
    if (!await canDeleteCategory(id)) {
      throw Exception('Cannot delete category with existing tasks');
    }
    
    final db = await _database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    _notifyCategoriesChanged();
  }

  @override
  Future<bool> canDeleteCategory(int id) async {
    final category = await getCategoryById(id);
    if (category == null) return false;
    
    // System categories cannot be deleted
    if (category.isSystem) return false;
    
    // Check if category has any tasks
    final usageCount = await getCategoryUsageCount(id);
    return usageCount == 0;
  }

  @override
  Future<int> getCategoryUsageCount(int id) async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM tasks
      WHERE category_id = ?
    ''', [id]);
    
    return maps.first['count'] as int;
  }

  @override
  Future<List<CategoryWithUsage>> getCategoriesWithUsage() async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        c.*,
        COALESCE(task_counts.total_tasks, 0) as task_count,
        COALESCE(task_counts.completed_tasks, 0) as completed_task_count,
        COALESCE(task_counts.pending_tasks, 0) as pending_task_count
      FROM categories c
      LEFT JOIN (
        SELECT 
          category_id,
          COUNT(*) as total_tasks,
          SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) as completed_tasks,
          SUM(CASE WHEN completed = 0 THEN 1 ELSE 0 END) as pending_tasks
        FROM tasks
        GROUP BY category_id
      ) as task_counts ON c.id = task_counts.category_id
      ORDER BY c.is_system DESC, c.name ASC
    ''');
    
    return maps.map((map) {
      final category = Category.fromJson(map);
      return CategoryWithUsage(
        category: category,
        taskCount: map['task_count'] as int,
        completedTaskCount: map['completed_task_count'] as int,
        pendingTaskCount: map['pending_task_count'] as int,
      );
    }).toList();
  }

  @override
  Stream<List<Category>> watchAllCategories() {
    // Initial load
    getAllCategories().then((categories) => _categoryStreamController.add(categories));
    return _categoryStreamController.stream;
  }

  @override
  Stream<List<CategoryWithUsage>> watchCategoriesWithUsage() {
    return watchAllCategories().asyncMap((_) => getCategoriesWithUsage());
  }

  void _notifyCategoriesChanged() {
    getAllCategories().then((categories) => _categoryStreamController.add(categories));
  }

  void dispose() {
    _categoryStreamController.close();
  }
}