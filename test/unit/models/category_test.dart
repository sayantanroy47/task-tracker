import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:task_tracker_app/shared/models/models.dart';
import '../../test_utils/fixtures.dart';

void main() {
  group('Category Model Tests', () {
    late Category sampleCategory;

    setUp(() {
      sampleCategory = Category(
        id: 'cat-test',
        name: 'Test Category',
        icon: 'test_icon',
        color: const Color(0xFF2196F3),
        isSystem: false,
        createdAt: DateTime.now(),
      );
    });

    group('Constructor Tests', () {
      test('should create category with all fields', () {
        final category = Category(
          id: 'cat-1',
          name: 'Work',
          icon: 'work',
          color: const Color(0xFF4CAF50),
          isSystem: true,
          createdAt: DateTime.now(),
        );

        expect(category.id, 'cat-1');
        expect(category.name, 'Work');
        expect(category.color, const Color(0xFF4CAF50));
        expect(category.icon, 'work');
        expect(category.isSystem, true);
        expect(category.createdAt, isA<DateTime>());
      });

      test('should create category with minimal required fields', () {
        final createdAt = DateTime.now();
        final category = Category(
          id: 'cat-minimal',
          name: 'Minimal',
          icon: 'icon',
          color: const Color(0xFF000000),
          isSystem: false,
          createdAt: createdAt,
        );

        expect(category.id, 'cat-minimal');
        expect(category.name, 'Minimal');
        expect(category.isSystem, false);
        expect(category.createdAt, createdAt);
      });
    });

    group('copyWith Method', () {
      test('should create copy with updated fields', () {
        final updatedCategory = sampleCategory.copyWith(
          name: 'Updated Name',
          color: const Color(0xFFFF0000),
          isSystem: true,
        );

        expect(updatedCategory.name, 'Updated Name');
        expect(updatedCategory.color, const Color(0xFFFF0000));
        expect(updatedCategory.isSystem, true);
        expect(updatedCategory.id, sampleCategory.id); // unchanged
        expect(updatedCategory.icon, sampleCategory.icon); // unchanged
      });

      test('should preserve unchanged fields', () {
        final updatedCategory = sampleCategory.copyWith(name: 'New Name');

        expect(updatedCategory.color, sampleCategory.color);
        expect(updatedCategory.icon, sampleCategory.icon);
        expect(updatedCategory.isSystem, sampleCategory.isSystem);
        expect(updatedCategory.createdAt, sampleCategory.createdAt);
      });

      test('should return identical instance when no changes', () {
        final unchangedCategory = sampleCategory.copyWith();

        expect(unchangedCategory.id, sampleCategory.id);
        expect(unchangedCategory.name, sampleCategory.name);
        expect(unchangedCategory.color, sampleCategory.color);
        expect(unchangedCategory.icon, sampleCategory.icon);
        expect(unchangedCategory.isSystem, sampleCategory.isSystem);
        expect(unchangedCategory.createdAt, sampleCategory.createdAt);
      });
    });

    group('Serialization Tests', () {
      test('toMap should serialize category correctly', () {
        final category = CategoryFixtures.createCategory(
          id: 'cat-1',
          name: 'Personal',
          description: 'Personal tasks',
          color: 0xFF2196F3,
          icon: 'person',
          isDefault: true,
          createdAt: DateTime(2024, 3, 15, 10, 0),
        );

        final map = category.toMap();

        expect(map['id'], 'cat-1');
        expect(map['name'], 'Personal');
        expect(map['description'], 'Personal tasks');
        expect(map['color'], 0xFF2196F3);
        expect(map['icon'], 'person');
        expect(map['is_default'], 1); // boolean converted to int
        expect(map['created_at'], '2024-03-15T10:00:00.000');
      });

      test('toJson should return same as toMap', () {
        final category = CategoryFixtures.createCategory();
        final map = category.toMap();
        final json = category.toJson();

        expect(json, equals(map));
      });

      test('fromMap should deserialize category correctly', () {
        final map = {
          'id': 'cat-1',
          'name': 'Work',
          'description': 'Work-related tasks',
          'color': 0xFF4CAF50,
          'icon': 'work',
          'is_default': 1,
          'created_at': '2024-03-15T10:00:00.000',
        };

        final category = Category.fromMap(map);

        expect(category.id, 'cat-1');
        expect(category.name, 'Work');
        expect(category.description, 'Work-related tasks');
        expect(category.color, 0xFF4CAF50);
        expect(category.icon, 'work');
        expect(category.isDefault, true);
        expect(category.createdAt, DateTime(2024, 3, 15, 10, 0));
      });

      test('fromMap should handle is_default as 0', () {
        final map = {
          'id': 'cat-1',
          'name': 'Custom',
          'description': 'Custom category',
          'color': 0xFF000000,
          'icon': 'custom',
          'is_default': 0,
          'created_at': '2024-03-15T10:00:00.000',
        };

        final category = Category.fromMap(map);
        expect(category.isDefault, false);
      });

      test('fromMap should handle missing optional fields', () {
        final map = {
          'id': 'cat-minimal',
          'name': 'Minimal',
          'color': 0xFF000000,
          'icon': 'icon',
        };

        final category = Category.fromMap(map);

        expect(category.id, 'cat-minimal');
        expect(category.name, 'Minimal');
        expect(category.description, ''); // default value
        expect(category.isDefault, false); // default value
        expect(category.createdAt.isBefore(DateTime.now().add(const Duration(seconds: 1))), true);
      });

      test('fromMap should handle invalid date gracefully', () {
        final map = {
          'id': 'cat-1',
          'name': 'Test',
          'description': 'Test',
          'color': 0xFF000000,
          'icon': 'icon',
          'is_default': 0,
          'created_at': 'invalid-date',
        };

        final category = Category.fromMap(map);
        expect(category.createdAt.isBefore(DateTime.now().add(const Duration(seconds: 1))), true);
      });

      test('fromJson should work same as fromMap', () {
        final json = {
          'id': 'cat-1',
          'name': 'Test',
          'description': 'Test description',
          'color': 0xFF123456,
          'icon': 'test',
          'is_default': 1,
          'created_at': '2024-03-15T10:00:00.000',
        };

        final categoryFromMap = Category.fromMap(json);
        final categoryFromJson = Category.fromJson(json);

        expect(categoryFromJson.id, categoryFromMap.id);
        expect(categoryFromJson.name, categoryFromMap.name);
        expect(categoryFromJson.description, categoryFromMap.description);
        expect(categoryFromJson.color, categoryFromMap.color);
        expect(categoryFromJson.icon, categoryFromMap.icon);
        expect(categoryFromJson.isDefault, categoryFromMap.isDefault);
        expect(categoryFromJson.createdAt, categoryFromMap.createdAt);
      });
    });

    group('Equality and HashCode', () {
      test('should be equal when IDs match', () {
        final category1 = CategoryFixtures.createCategory(
          id: 'same-id',
          name: 'Category 1',
        );
        final category2 = CategoryFixtures.createCategory(
          id: 'same-id',
          name: 'Category 2',
        );

        expect(category1, equals(category2));
        expect(category1.hashCode, equals(category2.hashCode));
      });

      test('should not be equal when IDs differ', () {
        final category1 = CategoryFixtures.createCategory(
          id: 'id-1',
          name: 'Same Name',
        );
        final category2 = CategoryFixtures.createCategory(
          id: 'id-2',
          name: 'Same Name',
        );

        expect(category1, isNot(equals(category2)));
        expect(category1.hashCode, isNot(equals(category2.hashCode)));
      });

      test('should be equal to itself', () {
        expect(sampleCategory, equals(sampleCategory));
        expect(sampleCategory.hashCode, equals(sampleCategory.hashCode));
      });
    });

    group('toString Method', () {
      test('should return readable string representation', () {
        final category = CategoryFixtures.createCategory(
          id: 'cat-work',
          name: 'Work',
          isDefault: true,
        );

        final string = category.toString();

        expect(string, contains('cat-work'));
        expect(string, contains('Work'));
        expect(string, contains('true'));
      });

      test('should handle special characters in name', () {
        final category = CategoryFixtures.createCategory(
          id: 'cat-special',
          name: 'Special & Chars! 🎯',
        );

        final string = category.toString();
        expect(string, contains('Special & Chars! 🎯'));
      });
    });

    group('Default Categories Tests', () {
      test('should create all default categories correctly', () {
        final defaultCategories = CategoryFixtures.createDefaultCategories();

        expect(defaultCategories.length, 6);

        final categoryNames = defaultCategories.map((c) => c.name).toSet();
        expect(categoryNames, contains('Personal'));
        expect(categoryNames, contains('Work'));
        expect(categoryNames, contains('Household'));
        expect(categoryNames, contains('Health'));
        expect(categoryNames, contains('Finance'));
        expect(categoryNames, contains('Family'));

        // All should be marked as default
        expect(defaultCategories.every((c) => c.isDefault), true);

        // All should have unique IDs
        final ids = defaultCategories.map((c) => c.id).toSet();
        expect(ids.length, defaultCategories.length);
      });

      test('default categories should have appropriate colors', () {
        final defaultCategories = CategoryFixtures.createDefaultCategories();
        
        for (final category in defaultCategories) {
          expect(category.color, isA<int>());
          expect(category.color & 0xFF000000, 0xFF000000); // Alpha channel should be set
        }
      });

      test('default categories should have appropriate icons', () {
        final defaultCategories = CategoryFixtures.createDefaultCategories();
        
        for (final category in defaultCategories) {
          expect(category.icon.isNotEmpty, true);
          expect(category.icon, isA<String>());
        }
      });
    });

    group('Edge Cases', () {
      test('should handle very long names', () {
        final longName = 'A' * 500;
        final category = CategoryFixtures.createCategory(name: longName);

        expect(category.name, longName);
        expect(category.name.length, 500);
      });

      test('should handle very long descriptions', () {
        final longDescription = 'Description ' * 100;
        final category = CategoryFixtures.createCategory(description: longDescription);

        expect(category.description, longDescription);
      });

      test('should handle special characters in all text fields', () {
        const specialName = '!@#\$%^&*()_+ 🎯📝✅';
        const specialDescription = 'Category with emojis: 🎯📝✅ and symbols: !@#\$%';
        const specialIcon = 'icon_with_underscore_123';

        final category = CategoryFixtures.createCategory(
          name: specialName,
          description: specialDescription,
          icon: specialIcon,
        );

        expect(category.name, specialName);
        expect(category.description, specialDescription);
        expect(category.icon, specialIcon);
      });

      test('should handle extreme color values', () {
        final category1 = CategoryFixtures.createCategory(color: 0x00000000); // Fully transparent black
        final category2 = CategoryFixtures.createCategory(color: 0xFFFFFFFF); // Fully opaque white
        final category3 = CategoryFixtures.createCategory(color: 0x80808080); // Semi-transparent gray

        expect(category1.color, 0x00000000);
        expect(category2.color, 0xFFFFFFFF);
        expect(category3.color, 0x80808080);
      });

      test('should handle empty strings gracefully', () {
        final map = {
          'id': '',
          'name': '',
          'description': '',
          'color': 0xFF000000,
          'icon': '',
          'is_default': 0,
          'created_at': '2024-03-15T10:00:00.000',
        };

        final category = Category.fromMap(map);

        expect(category.id, '');
        expect(category.name, '');
        expect(category.description, '');
        expect(category.icon, '');
      });

      test('should handle null values in fromMap gracefully', () {
        final map = {
          'id': null,
          'name': null,
          'description': null,
          'color': null,
          'icon': null,
          'is_default': null,
          'created_at': null,
        };

        final category = Category.fromMap(map);

        expect(category.id, ''); // null converted to empty string
        expect(category.name, ''); // fallback to default
        expect(category.description, ''); // fallback to default
        expect(category.color, 0xFF000000); // fallback to default
        expect(category.icon, 'category'); // fallback to default
        expect(category.isDefault, false); // fallback to default
      });
    });

    group('Custom Categories Tests', () {
      test('should create custom categories with proper defaults', () {
        final customCategories = CategoryFixtures.createCustomCategories(count: 3);

        expect(customCategories.length, 3);
        
        for (int i = 0; i < customCategories.length; i++) {
          final category = customCategories[i];
          expect(category.id, 'custom-${i + 1}');
          expect(category.name, 'Custom Category ${i + 1}');
          expect(category.isDefault, false);
          expect(category.color, isA<int>());
        }
      });

      test('custom categories should have unique colors', () {
        final customCategories = CategoryFixtures.createCustomCategories(count: 5);
        final colors = customCategories.map((c) => c.color).toSet();
        
        expect(colors.length, customCategories.length); // All colors should be unique
      });
    });
  });
}