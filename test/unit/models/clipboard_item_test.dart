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

    group('置顶功能扩展 (T043)', () {
      test('应该正确序列化置顶字段', () {
        // Arrange
        final item = ClipboardItem(
          id: 'test-id',
          content: 'test content',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.parse('2026-01-12T10:00:00.000Z'),
          hash: 'abc123',
          size: 12,
          pinned: true,
          pinnedAt: DateTime.parse('2026-01-12T11:30:00.000Z'),
        );

        // Act
        final json = item.toJson();

        // Assert
        expect(json['pinned'], true);
        expect(json['pinnedAt'], '2026-01-12T11:30:00.000Z');
      });

      test('应该正确反序列化置顶字段', () {
        // Arrange
        final json = {
          'id': 'test-id',
          'content': 'test content',
          'type': 'text',
          'category': 'text',
          'timestamp': '2026-01-12T10:00:00.000Z',
          'hash': 'abc123',
          'size': 12,
          'pinned': true,
          'pinnedAt': '2026-01-12T11:30:00.000Z',
        };

        // Act
        final item = ClipboardItem.fromJson(json);

        // Assert
        expect(item.pinned, true);
        expect(item.pinnedAt, DateTime.parse('2026-01-12T11:30:00.000Z'));
      });

      test('向后兼容:缺少pinned字段时应该默认为false', () {
        // Arrange - 旧格式JSON,没有pinned字段
        final json = {
          'id': 'test-id',
          'content': 'test content',
          'type': 'text',
          'category': 'text',
          'timestamp': '2026-01-12T10:00:00.000Z',
          'hash': 'abc123',
          'size': 12,
        };

        // Act
        final item = ClipboardItem.fromJson(json);

        // Assert
        expect(item.pinned, false);
        expect(item.pinnedAt, null);
      });

      test('向后兼容:pinned为null时应该默认为false', () {
        // Arrange - 旧格式JSON,pinned字段显式为null
        final json = {
          'id': 'test-id',
          'content': 'test content',
          'type': 'text',
          'category': 'text',
          'timestamp': '2026-01-12T10:00:00.000Z',
          'hash': 'abc123',
          'size': 12,
          'pinned': null,
        };

        // Act
        final item = ClipboardItem.fromJson(json);

        // Assert
        expect(item.pinned, false);
        expect(item.pinnedAt, null);
      });

      test('应该正确序列化未置顶状态', () {
        // Arrange
        final item = ClipboardItem(
          id: 'test-id',
          content: 'test content',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.parse('2026-01-12T10:00:00.000Z'),
          hash: 'abc123',
          size: 12,
          pinned: false,
          pinnedAt: null,
        );

        // Act
        final json = item.toJson();

        // Assert
        expect(json['pinned'], false);
        expect(json['pinnedAt'], null);
      });

      test('应该能复制并修改pinned字段', () {
        // Arrange
        final item = ClipboardItem(
          id: 'test-id',
          content: 'test content',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.parse('2026-01-12T10:00:00.000Z'),
          hash: 'abc123',
          size: 12,
          pinned: false,
        );

        // Act
        final pinnedItem = item.copyWith(
          pinned: true,
          pinnedAt: DateTime.parse('2026-01-12T11:30:00.000Z'),
        );

        // Assert
        expect(pinnedItem.pinned, true);
        expect(pinnedItem.pinnedAt, DateTime.parse('2026-01-12T11:30:00.000Z'));
        // 其他字段应该保持不变
        expect(pinnedItem.id, item.id);
        expect(pinnedItem.content, item.content);
      });

      test('应该能复制并取消置顶', () {
        // Arrange
        final item = ClipboardItem(
          id: 'test-id',
          content: 'test content',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.parse('2026-01-12T10:00:00.000Z'),
          hash: 'abc123',
          size: 12,
          pinned: true,
          pinnedAt: DateTime.parse('2026-01-12T11:30:00.000Z'),
        );

        // Act - 使用 clearPinnedAt 参数清除置顶时间
        final unpinnedItem = item.copyWith(
          pinned: false,
          clearPinnedAt: true,
        );

        // Assert
        expect(unpinnedItem.pinned, false);
        expect(unpinnedItem.pinnedAt, null);
      });

      test('pinned=true时isPinned应该返回true', () {
        // Arrange
        final item = ClipboardItem(
          id: 'test-id',
          content: 'test content',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.parse('2026-01-12T10:00:00.000Z'),
          hash: 'abc123',
          size: 12,
          pinned: true,
          pinnedAt: DateTime.parse('2026-01-12T11:30:00.000Z'),
        );

        // Act & Assert
        expect(item.isPinned, true);
      });

      test('pinned=false时isPinned应该返回false', () {
        // Arrange
        final item = ClipboardItem(
          id: 'test-id',
          content: 'test content',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.parse('2026-01-12T10:00:00.000Z'),
          hash: 'abc123',
          size: 12,
          pinned: false,
        );

        // Act & Assert
        expect(item.isPinned, false);
      });

      test('pinned=true但pinnedAt为null时应该保持一致', () {
        // 这是一个异常情况,但为了健壮性需要处理
        final item = ClipboardItem(
          id: 'test-id',
          content: 'test content',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.parse('2026-01-12T10:00:00.000Z'),
          hash: 'abc123',
          size: 12,
          pinned: true,
          pinnedAt: null, // 异常状态
        );

        expect(item.pinned, true);
        expect(item.pinnedAt, null);
        expect(item.isPinned, true);
      });
    });
  });
}
