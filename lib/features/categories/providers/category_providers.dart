import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/category.dart';
import '../../../shared/providers/app_providers.dart';
import '../domain/category_repository.dart';

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

/// Categories with task counts provider
final categoriesWithCountsProvider = FutureProvider<List<CategoryWithCount>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategoriesWithTaskCounts();
});

/// Category usage statistics provider
final categoryUsageStatsProvider = FutureProvider<Map<String, int>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategoryUsageStats();
});

/// Single category provider - parameterized
final singleCategoryProvider = StreamProvider.family<Category?, String>((ref, categoryId) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.watchCategory(categoryId);
});

/// Default categories provider - convenient access to system defaults
final defaultCategoriesProvider = Provider<List<Category>>((ref) {
  return Category.defaultCategories;
});

/// Category operations provider for CRUD operations
final categoryOperationsProvider = Provider<CategoryOperations>((ref) {
  return CategoryOperations(ref);
});

/// Most used categories provider - sorted by usage
final mostUsedCategoriesProvider = FutureProvider<List<CategoryWithCount>>((ref) async {
  final categoriesWithCounts = await ref.watch(categoriesWithCountsProvider.future);
  
  // Sort by task count in descending order
  categoriesWithCounts.sort((a, b) => b.taskCount.compareTo(a.taskCount));
  
  // Return top 6 categories or all if less than 6
  return categoriesWithCounts.take(6).toList();
});

/// Category suggestion provider - suggests category based on task content
final categorySuggestionProvider = FutureProvider.family<Category?, TaskContent>((ref, taskContent) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.suggestCategory(taskContent.title, taskContent.description);
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
  Future<Category> updateCategory(Category category) async {
    return await _repository.updateCategory(category);
  }
  
  /// Delete a category (only user categories)
  Future<bool> deleteCategory(String id) async {
    final category = await _repository.getCategoryById(id);
    if (category == null) {
      throw Exception('Category not found');
    }
    
    if (category.isSystem) {
      throw Exception('Cannot delete system category');
    }
    
    return await _repository.deleteCategory(id);
  }
  
  /// Search categories by name
  Future<List<Category>> searchCategories(String query) async {
    return await _repository.searchCategories(query);
  }
  
  /// Get category by name
  Future<Category?> getCategoryByName(String name) async {
    return await _repository.getCategoryByName(name);
  }
  
  /// Initialize default categories if needed
  Future<void> ensureDefaultCategories() async {
    final hasDefaults = await _repository.hasDefaultCategories();
    if (!hasDefaults) {
      await _repository.initializeDefaultCategories();
    }
  }
  
  /// Suggest category for task content
  Future<Category?> suggestCategoryForTask(String title, {String? description}) async {
    return await _repository.suggestCategory(title, description);
  }
}

/// Task content for category suggestion
class TaskContent {
  final String title;
  final String? description;
  
  const TaskContent({
    required this.title,
    this.description,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskContent &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          description == other.description;
  
  @override
  int get hashCode => title.hashCode ^ description.hashCode;
}

/// Helper functions for category operations

/// Get category color palette for UI selection
List<Color> getCategoryColorPalette() {
  return [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.pink,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.cyan,
    Colors.amber,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.lightBlue,
    Colors.lightGreen,
    Colors.lime,
    Colors.brown,
  ];
}

/// Get category icon options for UI selection
List<IconData> getCategoryIconOptions() {
  return [
    Icons.person,
    Icons.home,
    Icons.work,
    Icons.family_restroom,
    Icons.local_hospital,
    Icons.attach_money,
    Icons.school,
    Icons.fitness_center,
    Icons.restaurant,
    Icons.shopping_cart,
    Icons.car_rental,
    Icons.travel_explore,
    Icons.pets,
    Icons.music_note,
    Icons.book,
    Icons.computer,
    Icons.phone,
    Icons.email,
    Icons.calendar_today,
    Icons.star,
  ];
}