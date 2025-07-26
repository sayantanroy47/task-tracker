import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Category model for organizing tasks
/// Includes 6 default categories optimized for forgetful users
class Category {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final bool isSystem;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isSystem = false,
    required this.createdAt,
  });

  /// Create a copy of this category with some fields updated
  Category copyWith({
    String? id,
    String? name,
    String? icon,
    Color? color,
    bool? isSystem,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Category{id: $id, name: $name, icon: $icon}';
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color.value,
      'isSystem': isSystem ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Create from Map (database)
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      color: Color(map['color']),
      isSystem: map['isSystem'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  /// Get default system categories
  static List<Category> getDefaultCategories() {
    final now = DateTime.now();
    return [
      Category(
        id: 'personal',
        name: 'Personal',
        icon: '👤',
        color: AppColors.personal,
        isSystem: true,
        createdAt: now,
      ),
      Category(
        id: 'household',
        name: 'Household',
        icon: '🏠',
        color: AppColors.household,
        isSystem: true,
        createdAt: now,
      ),
      Category(
        id: 'work',
        name: 'Work',
        icon: '💼',
        color: AppColors.work,
        isSystem: true,
        createdAt: now,
      ),
      Category(
        id: 'family',
        name: 'Family',
        icon: '👨‍👩‍👧‍👦',
        color: AppColors.family,
        isSystem: true,
        createdAt: now,
      ),
      Category(
        id: 'health',
        name: 'Health',
        icon: '🏥',
        color: AppColors.health,
        isSystem: true,
        createdAt: now,
      ),
      Category(
        id: 'finance',
        name: 'Finance',
        icon: '💰',
        color: AppColors.finance,
        isSystem: true,
        createdAt: now,
      ),
    ];
  }

  /// Get category by ID from default categories
  static Category? getDefaultCategoryById(String id) {
    return getDefaultCategories().cast<Category?>().firstWhere(
      (category) => category?.id == id,
      orElse: () => null,
    );
  }

  /// Get icon for IconData
  IconData get iconData {
    // Map common icon names to Material Icons
    switch (icon.toLowerCase()) {
      case '👤':
      case 'personal':
        return Icons.person;
      case '🏠':
      case 'household':
        return Icons.home;
      case '💼':
      case 'work':
        return Icons.work;
      case '👨‍👩‍👧‍👦':
      case 'family':
        return Icons.family_restroom;
      case '🏥':
      case 'health':
        return Icons.local_hospital;
      case '💰':
      case 'finance':
        return Icons.attach_money;
      default:
        return Icons.label;
    }
  }
}