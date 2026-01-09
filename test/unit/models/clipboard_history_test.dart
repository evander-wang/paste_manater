import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/models/clipboard_history.dart';
import 'package:paste_manager/models/clipboard_item.dart';
import 'package:paste_manager/models/category.dart';

void main() {
  group('ClipboardHistory', () {
    test('应该创建空的历史记录', () {
      // Act
      final history = ClipboardHistory();

      // Assert
      expect(history.items, isEmpty);
      expect(history.totalCount, equals(0));
      expect(history.totalSize, equals(0));
    });

    test('应该正确添加项目', () {
      // Arrange
      final history = ClipboardHistory();
      final item = _createTestItem('id1', 'content1', 100);

      // Act
      final updated = history.add(item);

      // Assert
      expect(updated.totalCount, equals(1));
      expect(updated.totalSize, equals(100));
    });

    test('应该移除重复项目（5秒内相同内容）', () {
      // Arrange
      final history = ClipboardHistory();
      final item1 = _createTestItem('id1', 'same content', 100,
          timestamp: DateTime(2025, 1, 7, 12, 0, 0));
      final item2 = _createTestItem('id2', 'same content', 100,
          timestamp: DateTime(2025, 1, 7, 12, 0, 3), // 3 秒后
          hash: 'samehash');

      // Act
      final updated1 = history.add(item1);
      final updated2 = updated1.add(item2);

      // Assert
      expect(updated1.totalCount, equals(1));
      expect(updated2.totalCount, equals(1)); // item2 被识别为重复，不添加
    });

    test('应该在超过最大项目数时移除最旧项目', () {
      // Arrange
      final history = ClipboardHistory(maxItems: 3);

      // Act: 添加 4 个项目
      var updated = history;
      for (int i = 0; i < 4; i++) {
        final item = _createTestItem('id$i', 'content$i', 100,
            timestamp: DateTime(2025, 1, 7, 12, 0, i));
        updated = updated.add(item);
      }

      // Assert
      expect(updated.totalCount, equals(3)); // 最多保留 3 个
      expect(updated.items.any((item) => item.id == 'id0'), isFalse); // 最旧的被移除
    });

    test('应该在超过最大大小时移除项目', () {
      // Arrange
      const maxSize = 250; // 最多 250 字节
      final history = ClipboardHistory(maxSize: maxSize);

      // Act: 添加 3 个项目（每个 100 字节）
      var updated = history;
      for (int i = 0; i < 3; i++) {
        final item = _createTestItem('id$i', 'content$i', 100);
        updated = updated.add(item);
      }

      // Assert
      expect(updated.totalSize, lessThanOrEqualTo(maxSize));
      expect(updated.totalCount, lessThan(3)); // 至少移除 1 个以满足大小限制
    });

    test('应该正确按时间倒序排列项目', () {
      // Arrange
      final history = ClipboardHistory();

      // Act: 添加 3 个不同时间的项目
      var updated = history;
      final items = [
        _createTestItem('id1', 'content1', 100, timestamp: DateTime(2025, 1, 7, 12, 0, 1)),
        _createTestItem('id2', 'content2', 100, timestamp: DateTime(2025, 1, 7, 12, 0, 0)),
        _createTestItem('id3', 'content3', 100, timestamp: DateTime(2025, 1, 7, 12, 0, 2)),
      ];

      for (final item in items) {
        updated = updated.add(item);
      }

      // Assert: 应该按时间倒序（最新的在前）
      expect(updated.items[0].id, equals('id3')); // 最新
      expect(updated.items[1].id, equals('id1'));
      expect(updated.items[2].id, equals('id2')); // 最旧
    });

    test('应该正确移除指定项目', () {
      // Arrange
      final history = ClipboardHistory();
      final item1 = _createTestItem('id1', 'content1', 100);
      final item2 = _createTestItem('id2', 'content2', 100);
      final updated = history.add(item1).add(item2);

      // Act
      final removed = updated.remove('id1');

      // Assert
      expect(removed.totalCount, equals(1));
      expect(removed.items.any((item) => item.id == 'id1'), isFalse);
      expect(removed.items.any((item) => item.id == 'id2'), isTrue);
    });

    test('应该正确清空历史', () {
      // Arrange
      final history = ClipboardHistory();
      final item = _createTestItem('id1', 'content1', 100);
      final updated = history.add(item);

      // Act
      final cleared = updated.clear();

      // Assert
      expect(cleared.totalCount, equals(0));
      expect(cleared.items, isEmpty);
    });

    test('应该正确按分类过滤', () {
      // Arrange
      final history = ClipboardHistory();
      final item1 = _createTestItem('id1', 'text', 100, category: Category.text);
      final item2 = _createTestItem('id2', 'https://example.com', 100, category: Category.link);
      final updated = history.add(item1).add(item2);

      // Act
      final textItems = updated.filterBy(Category.text);
      final linkItems = updated.filterBy(Category.link);

      // Assert
      expect(textItems.length, equals(1));
      expect(textItems[0].id, equals('id1'));
      expect(linkItems.length, equals(1));
      expect(linkItems[0].id, equals('id2'));
    });

    test('应该正确搜索项目', () {
      // Arrange
      final history = ClipboardHistory();
      final item1 = _createTestItem('id1', 'hello world', 100);
      final item2 = _createTestItem('id2', 'goodbye world', 100);
      final updated = history.add(item1).add(item2);

      // Act
      final results = updated.search('hello');

      // Assert
      expect(results.length, equals(1));
      expect(results[0].id, equals('id1'));
    });

    test('应该正确序列化和反序列化 JSON', () {
      // Arrange
      final history = ClipboardHistory(
        initialItems: [
          _createTestItem('id1', 'content1', 100),
          _createTestItem('id2', 'content2', 100),
        ],
        maxItems: 1000,
        maxSize: 100 * 1024 * 1024,
      );

      // Act
      final json = history.toJson();
      final restored = ClipboardHistory.fromJson(json);

      // Assert
      expect(restored.totalCount, equals(history.totalCount));
      expect(restored.maxItems, equals(history.maxItems));
      expect(restored.maxSize, equals(history.maxSize));
    });
  });

  group('ClipboardHistory 边界情况', () {
    test('应该处理空内容的项目', () {
      // Arrange
      final history = ClipboardHistory();
      final item = _createTestItem('id1', '', 0);

      // Act
      final updated = history.add(item);

      // Assert
      expect(updated.totalCount, equals(1));
      expect(updated.items[0].content, equals(''));
    });

    test('应该正确获取最旧的项目', () {
      // Arrange
      final history = ClipboardHistory();
      final item1 = _createTestItem('id1', 'content1', 100,
          timestamp: DateTime(2025, 1, 7, 10, 0, 0));
      final item2 = _createTestItem('id2', 'content2', 100,
          timestamp: DateTime(2025, 1, 7, 12, 0, 0));
      final updated = history.add(item1).add(item2);

      // Act
      final oldest = updated.oldest;

      // Assert
      expect(oldest, isNotNull);
      expect(oldest!.id, equals('id1'));
    });

    test('空历史应该返回 null 作为最旧项目', () {
      // Arrange
      final history = ClipboardHistory();

      // Act
      final oldest = history.oldest;

      // Assert
      expect(oldest, isNull);
    });
  });
}

ClipboardItem _createTestItem(
  String id,
  String content,
  int size, {
  Category? category,
  DateTime? timestamp,
  String? hash,
}) {
  return ClipboardItem(
    id: id,
    content: content,
    type: ClipboardItemType.text,
    category: category ?? Category.text,
    timestamp: timestamp ?? DateTime(2025, 1, 7, 12, 0, 0),
    hash: hash ?? 'hash_$id',
    size: size,
  );
}
