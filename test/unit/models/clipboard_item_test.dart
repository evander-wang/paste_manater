import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/models/clipboard_item.dart';
import 'package:paste_manager/models/category.dart';

void main() {
  group('ClipboardItem', () {
    test('应该正确创建 ClipboardItem', () {
      // Arrange
      final id = 'test-id';
      final content = '测试内容';
      final type = ClipboardItemType.text;
      final category = Category.text;
      final timestamp = DateTime(2025, 1, 7, 12, 0, 0);
      final hash = 'abc12345';
      final size = 100;

      // Act
      final item = ClipboardItem(
        id: id,
        content: content,
        type: type,
        category: category,
        timestamp: timestamp,
        hash: hash,
        size: size,
      );

      // Assert
      expect(item.id, equals(id));
      expect(item.content, equals(content));
      expect(item.type, equals(type));
      expect(item.category, equals(category));
      expect(item.timestamp, equals(timestamp));
      expect(item.hash, equals(hash));
      expect(item.size, equals(size));
    });

    test('应该正确序列化和反序列化 JSON', () {
      // Arrange
      final originalItem = ClipboardItem(
        id: 'test-id',
        content: 'https://example.com',
        type: ClipboardItemType.url,
        category: Category.link,
        timestamp: DateTime(2025, 1, 7, 12, 0, 0),
        hash: 'abc12345',
        size: 100,
        sourceApp: 'com.apple.Safari',
      );

      // Act
      final json = originalItem.toJson();
      final restoredItem = ClipboardItem.fromJson(json);

      // Assert
      expect(restoredItem.id, equals(originalItem.id));
      expect(restoredItem.content, equals(originalItem.content));
      expect(restoredItem.type, equals(originalItem.type));
      expect(restoredItem.category, equals(originalItem.category));
      expect(restoredItem.timestamp, equals(originalItem.timestamp));
      expect(restoredItem.hash, equals(originalItem.hash));
      expect(restoredItem.size, equals(originalItem.size));
      expect(restoredItem.sourceApp, equals(originalItem.sourceApp));
    });

    test('应该正确识别重复项目（相同哈希 + 5秒内）', () {
      // Arrange
      final item1 = ClipboardItem(
        id: 'id1',
        content: '相同内容',
        type: ClipboardItemType.text,
        category: Category.text,
        timestamp: DateTime(2025, 1, 7, 12, 0, 0),
        hash: 'samehash',
        size: 100,
      );

      final item2 = ClipboardItem(
        id: 'id2',
        content: '相同内容',
        type: ClipboardItemType.text,
        category: Category.text,
        timestamp: DateTime(2025, 1, 7, 12, 0, 3), // 3 秒后
        hash: 'samehash',
        size: 100,
      );

      final item3 = ClipboardItem(
        id: 'id3',
        content: '相同内容',
        type: ClipboardItemType.text,
        category: Category.text,
        timestamp: DateTime(2025, 1, 7, 12, 0, 6), // 6 秒后
        hash: 'samehash',
        size: 100,
      );

      // Act & Assert
      expect(item1.isDuplicate(item2), isTrue); // 3 秒内，是重复
      expect(item1.isDuplicate(item3), isFalse); // 6 秒，不是重复
    });

    test('应该处理可选的 sourceApp 字段', () {
      // Arrange
      final itemWithSource = ClipboardItem(
        id: 'id1',
        content: 'content',
        type: ClipboardItemType.text,
        category: Category.text,
        timestamp: DateTime.now(),
        hash: 'hash',
        size: 100,
        sourceApp: 'com.apple.Safari',
      );

      final itemWithoutSource = ClipboardItem(
        id: 'id2',
        content: 'content',
        type: ClipboardItemType.text,
        category: Category.text,
        timestamp: DateTime.now(),
        hash: 'hash',
        size: 100,
      );

      // Act
      final json1 = itemWithSource.toJson();
      final json2 = itemWithoutSource.toJson();

      // Assert
      expect(json1.containsKey('sourceApp'), isTrue);
      expect(json2.containsKey('sourceApp'), isFalse);
    });
  });
}
