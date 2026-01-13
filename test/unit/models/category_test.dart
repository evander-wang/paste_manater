import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/models/category.dart';
import 'package:paste_manager/models/clipboard_item.dart';

void main() {
  group('CategoryClassifier', () {
    test('应该将 http/https URL 识别为链接', () {
      // Arrange & Act
      final category1 = CategoryClassifier.classify(
        'https://www.example.com',
        ClipboardDataType.text,
      );
      final category2 = CategoryClassifier.classify(
        'http://test.org',
        ClipboardDataType.text,
      );

      // Assert
      expect(category1, equals(Category.link));
      expect(category2, equals(Category.link));
    });

    test('应该将纯文本识别为文本', () {
      // Arrange & Act
      final category = CategoryClassifier.classify(
        '这是一段普通文本',
        ClipboardDataType.text,
      );

      // Assert
      expect(category, equals(Category.text));
    });

    test('应该将 Unix 文件路径识别为文件', () {
      // Arrange & Act
      final category = CategoryClassifier.classify(
        '/Users/username/Documents/file.txt',
        ClipboardDataType.text,
      );

      // Assert
      expect(category, equals(Category.file));
    });

    test('应该将 Windows 文件路径识别为文件', () {
      // Arrange & Act
      final category = CategoryClassifier.classify(
        r'C:\Users\username\Documents\file.txt',
        ClipboardDataType.text,
      );

      // Assert
      expect(category, equals(Category.file));
    });

    test('应该将代码识别为代码', () {
      // Arrange & Act
      final category1 = CategoryClassifier.classify(
        'function test() { return true; }',
        ClipboardDataType.text,
      );
      final category2 = CategoryClassifier.classify(
        'class MyClass { constructor() {} }',
        ClipboardDataType.text,
      );

      // Assert
      expect(category1, equals(Category.code));
      expect(category2, equals(Category.code));
    });

    test('URL 应该比文件路径优先级高', () {
      // Arrange & Act
      final category = CategoryClassifier.classify(
        'https://example.com/file.txt',
        ClipboardDataType.text,
      );

      // Assert
      expect(category, equals(Category.link)); // 应该是链接，不是文件
    });

    test('文件路径应该比代码优先级高', () {
      // Arrange & Act
      final category = CategoryClassifier.classify(
        '/Users/test/function.js',
        ClipboardDataType.text,
      );

      // Assert
      expect(category, equals(Category.file)); // 应该是文件，不是代码
    });

    test('应该正确获取分类显示名称', () {
      // Act & Assert
      expect(CategoryClassifier.getDisplayName(Category.text), equals('文本'));
      expect(CategoryClassifier.getDisplayName(Category.link), equals('链接'));
      expect(CategoryClassifier.getDisplayName(Category.code), equals('代码'));
      expect(CategoryClassifier.getDisplayName(Category.file), equals('文件'));
    });

    test('应该正确获取分类优先级', () {
      // Act & Assert
      expect(CategoryClassifier.getPriority(Category.link), equals(1));
      expect(CategoryClassifier.getPriority(Category.file), equals(2));
      expect(CategoryClassifier.getPriority(Category.code), equals(3));
      expect(CategoryClassifier.getPriority(Category.text), equals(4));
    });
  });
}
