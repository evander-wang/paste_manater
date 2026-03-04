import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/models/clipboard_history.dart';
import 'package:paste_manager/models/clipboard_item.dart';
import 'package:paste_manager/services/storage_service.dart';

void main() {
  group('StorageService', () {
    late StorageService storageService;

    setUp(() {
      storageService = StorageService();
    });

    test('应该加载空历史（当文件不存在时）', () async {
      // Act
      final history = await storageService.load();

      // Assert
      expect(history.totalCount, equals(0));
      expect(history.items, isEmpty);
    });

    test('应该保存和加载历史', () async {
      // Arrange
      final originalHistory = ClipboardHistory(
        initialItems: [
          ClipboardItem(
            id: 'test-id',
            content: 'test content',
            type: ClipboardItemType.text,
            categoryId: 'text',
            timestamp: DateTime(2025, 1, 7, 12, 0, 0),
            hash: 'testhash',
            size: 100,
          ),
        ],
        maxItems: 1000,
        maxSize: 100 * 1024 * 1024,
      );

      // Act
      await storageService.save(originalHistory);
      final loadedHistory = await storageService.load();

      // Assert
      expect(loadedHistory.totalCount, equals(originalHistory.totalCount));
      expect(loadedHistory.items[0].id, equals(originalHistory.items[0].id));
      expect(loadedHistory.items[0].content, equals(originalHistory.items[0].content));
    });

    test('应该正确序列化元数据', () async {
      // Arrange
      final history = ClipboardHistory(
        initialItems: [
          ClipboardItem(
            id: 'test-id',
            content: 'test content',
            type: ClipboardItemType.text,
            categoryId: 'text',
            timestamp: DateTime(2025, 1, 7, 12, 0, 0),
            hash: 'testhash',
            size: 100,
          ),
        ],
      );

      // Act
      await storageService.save(history);
      final loaded = await storageService.load();
      final json = history.toJson();

      // Assert
      expect(json['version'], equals(1));
      expect(json['maxItems'], equals(1000));
      expect(json['maxSize'], equals(100 * 1024 * 1024));
      expect(json['metadata'], isNotNull);
      expect(json['metadata']['totalCount'], equals(1));
      expect(json['metadata']['totalSize'], equals(100));
    });

    test('应该正确追加项目', () async {
      // Arrange
      final history = ClipboardHistory();
      final item = ClipboardItem(
        id: 'test-id',
        content: 'test content',
        type: ClipboardItemType.text,
        categoryId: 'text',
        timestamp: DateTime(2025, 1, 7, 12, 0, 0),
        hash: 'testhash',
        size: 100,
      );

      // Act
      await storageService.append(item);
      final loaded = await storageService.load();

      // Assert
      expect(loaded.totalCount, equals(1));
      expect(loaded.items[0].id, equals('test-id'));
    });

    test('应该正确清空历史', () async {
      // Arrange
      final history = ClipboardHistory(
        initialItems: [
          ClipboardItem(
            id: 'test-id',
            content: 'test content',
            type: ClipboardItemType.text,
            categoryId: 'text',
            timestamp: DateTime(2025, 1, 7, 12, 0, 0),
            hash: 'testhash',
            size: 100,
          ),
        ],
      );

      await storageService.save(history);

      // Act
      await storageService.clear();
      final loaded = await storageService.load();

      // Assert
      expect(loaded.totalCount, equals(0));
    });

    test('应该正确获取存储文件大小', () async {
      // Arrange
      final history = ClipboardHistory(
        initialItems: [
          ClipboardItem(
            id: 'test-id',
            content: 'test content',
            type: ClipboardItemType.text,
            categoryId: 'text',
            timestamp: DateTime(2025, 1, 7, 12, 0, 0),
            hash: 'testhash',
            size: 100,
          ),
        ],
      );

      await storageService.save(history);

      // Act
      final size = await storageService.getStorageSize();

      // Assert
      expect(size, greaterThan(0));
    });
  });
}
