import '../../shared/models/models.dart';

/// Abstract repository interface for category operations
abstract class CategoryRepository {
  /// Get all categories
  Future<List<Category>> getAllCategories();

  /// Get system categories only
  Future<List<Category>> getSystemCategories();

  /// Get user-created categories only
  Future<List<Category>> getUserCategories();

  /// Get category by ID
  Future<Category?> getCategoryById(String id);

  /// Get category by name
  Future<Category?> getCategoryByName(String name);

  /// Create a new category
  Future<Category> createCategory(Category category);

  /// Update an existing category
  Future<void> updateCategory(Category category);

  /// Delete a category (only user-created categories)
  Future<void> deleteCategory(String id);

  /// Check if category can be deleted (not system category and no tasks)
  Future<bool> canDeleteCategory(String id);

  /// Get category usage count (number of tasks)
  Future<int> getCategoryUsageCount(String id);

  /// Get categories with usage statistics
  Future<List<CategoryWithUsage>> getCategoriesWithUsage();

  /// Watch all categories (stream)
  Stream<List<Category>> watchAllCategories();

  /// Watch categories with usage statistics (stream)
  Stream<List<CategoryWithUsage>> watchCategoriesWithUsage();
}

/// Category model with usage statistics
class CategoryWithUsage {
  final Category category;
  final int taskCount;
  final int completedTaskCount;
  final int pendingTaskCount;

  const CategoryWithUsage({
    required this.category,
    required this.taskCount,
    required this.completedTaskCount,
    required this.pendingTaskCount,
  });

  double get completionRate {
    if (taskCount == 0) return 0.0;
    return completedTaskCount / taskCount;
  }
}