import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/category.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../core/repositories/category_repository.dart';

/// Category-related providers for state management
/// Handles category operations and state across the application

/// All categories provider - watches all categories in real-time
final allCategoriesProvider = StreamProvider<List<Category>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.watchAllCategories();
});

/// System categories provider - only system-defined categories
final systemCategoriesProvider = FutureProvider<List<Category>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getSystemCategories();
});

/// User categories provider - only user-created categories
final userCategoriesProvider = FutureProvider<List<Category>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getUserCategories();
});

/// Categories with usage statistics provider
final categoriesWithUsageProvider = StreamProvider<List<CategoryWithUsage>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.watchCategoriesWithUsage();
});

/// Default categories provider - convenient access to system defaults
final defaultCategoriesProvider = Provider<List<Category>>((ref) {
  return Category.getDefaultCategories();
});

/// Category operations provider for CRUD operations
final categoryOperationsProvider = Provider<CategoryOperations>((ref) {
  return CategoryOperations(ref);
});

/// Category operations class for handling CRUD operations
class CategoryOperations {
  final Ref _ref;
  
  CategoryOperations(this._ref);
  
  CategoryRepository get _repository => _ref.read(categoryRepositoryProvider);
  
  /// Create a new category
  Future<Category> createCategory({
    required String name,
    String? description,
    required Color color,
    required IconData icon,
  }) async {
    final category = Category.create(
      name: name,
      description: description,
      color: color,
      icon: icon,
      isSystem: false,
    );
    
    return await _repository.createCategory(category);
  }
  
  /// Update an existing category
  Future<void> updateCategory(Category category) async {
    return await _repository.updateCategory(category);
  }
  
  /// Delete a category (only user categories)
  Future<void> deleteCategory(String id) async {
    final canDelete = await _repository.canDeleteCategory(id);
    if (!canDelete) {
      throw Exception('Cannot delete category - it may be a system category or have associated tasks');
    }
    
    return await _repository.deleteCategory(id);
  }
  
  /// Get category by name
  Future<Category?> getCategoryByName(String name) async {
    return await _repository.getCategoryByName(name);
  }
  
  /// Get category by ID
  Future<Category?> getCategoryById(String id) async {
    return await _repository.getCategoryById(id);
  }
  
  /// Get category usage count
  Future<int> getCategoryUsageCount(String id) async {
    return await _repository.getCategoryUsageCount(id);
  }
  
  /// Check if category can be deleted
  Future<bool> canDeleteCategory(String id) async {
    return await _repository.canDeleteCategory(id);
  }
}