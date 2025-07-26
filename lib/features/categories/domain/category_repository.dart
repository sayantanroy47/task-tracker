import '../../../shared/models/category.dart';

/// Repository interface for category data operations
/// Manages task categorization and organization
abstract class CategoryRepository {
  /// Get all categories
  Future<List<Category>> getAllCategories();
  
  /// Get system-defined categories
  Future<List<Category>> getSystemCategories();
  
  /// Get user-created categories
  Future<List<Category>> getUserCategories();
  
  /// Get a single category by ID
  Future<Category?> getCategoryById(String id);
  
  /// Get category by name (case-insensitive)
  Future<Category?> getCategoryByName(String name);
  
  /// Create a new category
  Future<Category> createCategory(Category category);
  
  /// Update an existing category
  Future<Category> updateCategory(Category category);
  
  /// Delete a category by ID (only user categories)
  Future<bool> deleteCategory(String id);
  
  /// Search categories by name
  Future<List<Category>> searchCategories(String query);
  
  /// Initialize default system categories
  Future<void> initializeDefaultCategories();
  
  /// Check if default categories exist
  Future<bool> hasDefaultCategories();
  
  /// Get category usage statistics
  Future<Map<String, int>> getCategoryUsageStats();
  
  /// Get categories with task counts
  Future<List<CategoryWithCount>> getCategoriesWithTaskCounts();
  
  /// Suggest category based on task content
  Future<Category?> suggestCategory(String taskTitle, String? description);
  
  /// Listen to category changes (for real-time updates)
  Stream<List<Category>> watchAllCategories();
  Stream<Category?> watchCategory(String id);
}

/// Category with associated task count
class CategoryWithCount {
  final Category category;
  final int taskCount;
  final int completedCount;
  final int pendingCount;
  
  const CategoryWithCount({
    required this.category,
    required this.taskCount,
    required this.completedCount,
    required this.pendingCount,
  });
  
  double get completionRate => taskCount > 0 ? completedCount / taskCount : 0.0;
}