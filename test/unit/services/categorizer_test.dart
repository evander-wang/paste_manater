import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/models/clipboard_item.dart';
import 'package:paste_manager/models/category.dart';
import 'package:paste_manager/services/categorizer.dart';

void main() {
  group('Categorizer', () {
    test('应该正确分类 URL 为链接', () {
      // Arrange
      final item = ClipboardItem(
        id: 'test-id',
        content: 'https://www.example.com',
        type: ClipboardItemType.url,
        category: Category.text, // 初始分类错误
        timestamp: DateTime.now(),
        hash: 'hash',
        size: 100,
      );

      // Act
      final category = Categorizer.classifyItem(item);

      // Assert
      expect(category, equals(Category.link));
    });

    test('应该正确分类纯文本为文本', () {
      // Arrange
      final item = ClipboardItem(
        id: 'test-id',
        content: '这是一段普通文本',
        type: ClipboardItemType.text,
        category: Category.text,
        timestamp: DateTime.now(),
        hash: 'hash',
        size: 100,
      );

      // Act
      final category = Categorizer.classifyItem(item);

      // Assert
      expect(category, equals(Category.text));
    });

    test('应该正确分类图像为图像', () {
      // Arrange
      final item = ClipboardItem(
        id: 'test-id',
        content: 'image-data',
        type: ClipboardItemType.image,
        category: Category.text,
        timestamp: DateTime.now(),
        hash: 'hash',
        size: 100,
      );

      // Act
      final category = Categorizer.classifyItem(item);

      // Assert
      expect(category, equals(Category.image));
    });

    test('应该正确分类代码为代码', () {
      // Arrange
      final item = ClipboardItem(
        id: 'test-id',
        content: 'function test() { return true; }',
        type: ClipboardItemType.text,
        category: Category.text,
        timestamp: DateTime.now(),
        hash: 'hash',
        size: 100,
      );

      // Act
      final category = Categorizer.classifyItem(item);

      // Assert
      expect(category, equals(Category.code));
    });

    test('应该正确分类文件路径为文件', () {
      // Arrange
      final item = ClipboardItem(
        id: 'test-id',
        content: '/Users/username/Documents/file.txt',
        type: ClipboardFileType.text,
        category: Category.text,
        timestamp: DateTime.now(),
        hash: 'hash',
        size: 100,
      );

      // Act
      final category = Categorizer.classifyItem(item);

      // Assert
      expect(category, equals(Category.file));
    });

    test('应该正确批量分类项目', () {
      // Arrange
      final items = [
        ClipboardItem(
          id: 'id1',
          content: 'https://example.com',
          type: ClipboardItemType.url,
          category: Category.text,
          timestamp: DateTime.now(),
          hash: 'hash1',
          size: 100,
        ),
        ClipboardItem(
          id: 'id2',
          content: 'function test() {}',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.now(),
          hash: 'hash2',
          size: 100,
        ),
      ];

      // Act
      final classified = Categorizer.classifyItems(items);

      // Assert
      expect(classified[0].category, equals(Category.link));
      expect(classified[1].category, equals(Category.code));
    });

    test('应该正确计算分类统计', () {
      // Arrange
      final items = [
        _createTestItem('id1', Category.text),
        _createTestItem('id2', Category.text),
        _createTestItem('id3', Category.link),
      ];

      // Act
      final stats = Categorizer.getCategoryStats(items);

      // Assert
      expect(stats[Category.text], equals(2));
      expect(stats[Category.link], equals(1));
    });

    test('应该正确计算分类准确率', () {
      // Arrange
      final items = [
        _createTestItem('id1', Category.text),
        _createTestItem('id2', Category.link),
        _createTestItem('id3', Category.text), // 错误分类，实际是 link
      ];

      final expectedCategories = {
        'content1': Category.text,
        'content2': Category.link,
        'content3': Category.link, // 期望是 link
      };

      // Act
      final accuracy = Categorizer.calculateAccuracy(items, expectedCategories);

      // Assert
      expect(accuracy, equals(2 / 3)); // 2/3 正确
    });

    test('应该处理空项目列表', () {
      // Arrange
      final items = <ClipboardItem>[];
      final expectedCategories = <String, Category>{};

      // Act
      final accuracy = Categorizer.calculateAccuracy(items, expectedCategories);

      // Assert
      expect(accuracy, equals(1.0)); // 100% 准确率（空列表）
    });
  });

  group('Categorizer 准确率要求 (≥95%)', () {
    test('应该在常见内容类型上达到 95% 准确率', () {
      // Arrange
      final testCases = [
        // URL 测试（20 个）
        ...List.generate(20, (i) => _createTestItem(
          'url$i',
          'https://example.com/page$i',
          expected: Category.link,
        )),
        // 纯文本测试（20 个）
        ...List.generate(20, (i) => _createTestItem(
          'text$i',
          'This is plain text number $i',
          expected: Category.text,
        )),
        // 代码测试（20 个）
        ...List.generate(20, (i) => _createTestItem(
          'code$i',
          'function test$i() { return true; }',
          expected: Category.code,
        )),
        // 文件路径测试（20 个）
        ...List.generate(20, (i) => _createTestItem(
          'file$i',
          '/Users/test/file$i.txt',
          expected: Category.file,
        )),
      ];

      final expectedCategories = {
        for (var item in testCases)
          item.content: item.category,
      };

      // Act
      final classified = Categorizer.classifyItems(testCases);
      final accuracy = Categorizer.calculateAccuracy(classified, expectedCategories);

      // Assert
      expect(accuracy, greaterThanOrEqualTo(0.95)); // 至少 95% 准确率
    });
  });
}

ClipboardItem _createTestItem(
  String id,
  String content, {
  Category? category,
  Category? expected,
}) {
  return ClipboardItem(
    id: id,
    content: content,
    type: ClipboardItemType.text,
    category: category ?? Category.text,
    timestamp: DateTime.now(),
    hash: 'hash_$id',
    size: content.length,
  );
}
