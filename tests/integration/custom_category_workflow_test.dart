import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/services/category_manager.dart';
import 'package:paste_manager/services/category_storage.dart';
import 'package:paste_manager/models/custom_category.dart';

void main() {
  group('创建分类完整流程集成测试', () {
    late CategoryManager categoryManager;
    late CategoryStorage storage;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      storage = CategoryStorage();
      categoryManager = CategoryManager(storage: storage);

      // 清空测试数据
      await storage.saveCategories([]);
    });

    test('应该成功创建一个新的自定义分类', () async {
      // Act
      final category = await categoryManager.addCategory('工作');

      // Assert
      expect(category, isNotNull);
      expect(category.name, '工作');
      expect(category.id, startsWith('custom_'));
      expect(IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'), isA<IconData>());
      expect(category.color, isA<Color>());
      expect(category.createdAt, isA<DateTime>());
    });

    test('创建的分类应该持久化到文件', () async {
      // Act
      await categoryManager.addCategory('个人项目');

      // Assert - 重新加载应该能找到
      final categories = await storage.loadCategories();
      expect(categories.length, 1);
      expect(categories[0]['name'], '个人项目');
    });

    test('应该拒绝空名称', () async {
      // Act & Assert
      expect(
        () => categoryManager.addCategory(''),
        throwsA(isA<CategoryNameEmptyException>()),
      );
    });

    test('应该拒绝超过10字符的名称', () async {
      // Act & Assert
      expect(
        () => categoryManager.addCategory('这是超过十个字符限制的分类名称'),
        throwsA(isA<CategoryNameTooLongException>()),
      );
    });

    test('应该拒绝重复的名称', () async {
      // Arrange
      await categoryManager.addCategory('工作');

      // Act & Assert
      expect(
        () => categoryManager.addCategory('工作'),
        throwsA(isA<CategoryNameDuplicateException>()),
      );
    });

    test('应该检测到与预置分类重复的名称', () async {
      // Act & Assert
      expect(
        () => categoryManager.addCategory('文本'), // 预置分类名称
        throwsA(isA<CategoryNameDuplicateException>()),
      );
    });

    test('应该支持Unicode和emoji名称', () async {
      // Act
      final category1 = await categoryManager.addCategory('🎨设计');
      final category2 = await categoryManager.addCategory('😀开心');

      // Assert
      expect(category1.name, '🎨设计');
      expect(category2.name, '😀开心');

      final categories = await storage.loadCategories();
      expect(categories.length, 2);
    });

    test('应该自动分配随机图标和颜色', () async {
      // Act
      final categories = await Future.wait(
        List.generate(10, (_) => categoryManager.addCategory('分类${DateTime.now().millisecondsSinceEpoch}')),
      );

      // Assert
      final icons = categories.map((c) => c.iconCodePoint).toSet();
      final colors = categories.map((c) => c.color.value).toSet();

      // 应该有多个不同的图标和颜色（虽然不保证全部不同）
      expect(icons.length, greaterThan(1));
      expect(colors.length, greaterThan(1));
    });

    test('应该限制最多20个自定义分类', () async {
      // Arrange - 创建20个分类
      for (int i = 0; i < 20; i++) {
        await categoryManager.addCategory('分类$i');
      }

      // Act & Assert
      expect(
        () => categoryManager.addCategory('第21个'),
        throwsA(isA<CategoryLimitExceededException>()),
      );
    });

    test('getAllCategories应该包含预置和自定义分类', () async {
      // Arrange
      await categoryManager.addCategory('工作');
      await categoryManager.addCategory('学习');

      // Act
      final allCategories = categoryManager.getAllCategories();

      // Assert
      // 4个预置分类 + 2个自定义分类
      expect(allCategories.length, 6);

      final presetCategories = allCategories.where((c) => c.isPreset).toList();
      final customCategories = allCategories.where((c) => !c.isPreset).toList();

      expect(presetCategories.length, 4);
      expect(customCategories.length, 2);
      expect(customCategories[0].displayName, '工作');
      expect(customCategories[1].displayName, '学习');
    });

    test('getCategoryById应该正确查找分类', () async {
      // Arrange
      final created = await categoryManager.addCategory('测试分类');

      // Act
      final found = categoryManager.getCategoryById(created.id);

      // Assert
      expect(found, isNotNull);
      expect(found!.displayName, '测试分类');
      expect(found.isPreset, false);
    });

    test('getCategoryById应该支持预置分类', () async {
      // Act
      final textCategory = categoryManager.getCategoryById('text');
      final linkCategory = categoryManager.getCategoryById('link');

      // Assert
      expect(textCategory, isNotNull);
      expect(textCategory!.displayName, '文本');
      expect(linkCategory, isNotNull);
      expect(linkCategory!.displayName, '链接');
    });

    test('创建分类后应该立即可用于过滤', () async {
      // Arrange
      final category = await categoryManager.addCategory('重要文件');

      // Act
      final found = categoryManager.getCategoryById(category.id);

      // Assert
      expect(found, isNotNull);
      expect(found!.displayName, '重要文件');
    });
  });
}
