import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paste_manager/services/category_manager.dart';
import 'package:paste_manager/services/category_storage.dart';
import 'package:paste_manager/models/custom_category.dart';
import 'package:flutter/material.dart';

void main() {
  // 注册 Mocktail fallbacks
  registerFallbackValue(CustomCategory(
    id: 'test',
    name: 'test',
    icon: Icons.folder,
    color: Colors.blue,
    createdAt: DateTime.now(),
  ));

  group('CategoryManager - 删除分类', () {
    late CategoryManager manager;
    late MockCategoryStorage mockStorage;

    setUp(() {
      mockStorage = MockCategoryStorage();
      manager = CategoryManager(storage: mockStorage);
    });

    group('T039: 阻止删除预置分类', () {
      test('应该抛出PresetCategoryCannotBeDeletedException', () async {
        // Act & Assert
        expect(
          () async => await manager.deleteCategory('text'),
          throwsA(isA<PresetCategoryCannotBeDeletedException>()),
        );

        expect(
          () async => await manager.deleteCategory('link'),
          throwsA(isA<PresetCategoryCannotBeDeletedException>()),
        );

        expect(
          () async => await manager.deleteCategory('code'),
          throwsA(isA<PresetCategoryCannotBeDeletedException>()),
        );

        expect(
          () async => await manager.deleteCategory('file'),
          throwsA(isA<PresetCategoryCannotBeDeletedException>()),
        );
      });

      test('canDeleteCategory对预置分类应该返回false', () {
        // Act & Assert
        expect(manager.canDeleteCategory('text'), false);
        expect(manager.canDeleteCategory('link'), false);
        expect(manager.canDeleteCategory('code'), false);
        expect(manager.canDeleteCategory('file'), false);
      });
    });
  });

  group('T055: 移动项目到分类', () {
    test('应该成功将项目移动到目标分类', () async {
      // Arrange
      final mockStorage = MockCategoryStorage();
      final manager = CategoryManager(storage: mockStorage);

      final clipboardHistory = [
        {
          'id': 'item1',
          'content': 'test content',
          'categoryId': 'text',
        },
      ];

      // Act
      await manager.moveItemToCategory(
        clipboardHistory,
        'item1',
        'text', // 移动到相同分类（预置分类）
      );

      // Assert
      expect(clipboardHistory[0]['categoryId'], 'text');
    });

    test('当目标分类不存在时应该抛出CategoryNotFoundException', () async {
      // Arrange
      final mockStorage = MockCategoryStorage();
      final manager = CategoryManager(storage: mockStorage);

      final clipboardHistory = [
        {
          'id': 'item1',
          'content': 'test content',
        },
      ];

      // Act & Assert
      expect(
        () => manager.moveItemToCategory(
          clipboardHistory,
          'item1',
          'nonexistent_category',
        ),
        throwsA(isA<CategoryNotFoundException>()),
      );
    });

    test('当项目不存在时应该抛出ClipboardItemNotFoundException', () async {
      // Arrange
      final mockStorage = MockCategoryStorage();
      final manager = CategoryManager(storage: mockStorage);

      final clipboardHistory = [
        {
          'id': 'item1',
          'content': 'test content',
        },
      ];

      // Act & Assert
      expect(
        () => manager.moveItemToCategory(
          clipboardHistory,
          'nonexistent_item',
          'text',
        ),
        throwsA(isA<ClipboardItemNotFoundException>()),
      );
    });
  });
}

// Mock类使用 mocktail
class MockCategoryStorage extends Mock implements CategoryStorage {}
