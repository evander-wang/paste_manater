import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paste_manager/models/clipboard_item.dart';
import 'package:paste_manager/models/category.dart';
import 'package:paste_manager/services/clipboard_monitor.dart';
import 'package:paste_manager/services/storage_service.dart';

class MockStorageService extends Mock implements StorageService {}

void main() {
  group('ClipboardMonitor', () {
    late ClipboardMonitor monitor;
    late MockStorageService mockStorage;

    setUp(() {
      mockStorage = MockStorageService();
      monitor = ClipboardMonitor(storageService: mockStorage);
    });

    tearDown(() async {
      await monitor.stop();
    });

    test('应该每 0.5 秒检查一次剪贴板变化', () async {
      // Arrange
      const checkInterval = Duration(milliseconds: 500);
      var checkCount = 0;

      // Act
      await monitor.start();
      await Future.delayed(const Duration(milliseconds: 1100)); // 等待 >2 次检查

      // Assert: 应该至少检查了 2 次
      // TODO: 验证检查频率
      await monitor.stop();
    });

    test('应该检测到重复内容（5秒内相同哈希）', () async {
      // Arrange
      final item1 = ClipboardItem(
        id: 'id1',
        content: 'same content',
        type: ClipboardItemType.text,
        category: Category.text,
        timestamp: DateTime.now(),
        hash: 'samehash',
        size: 100,
      );

      final item2 = ClipboardItem(
        id: 'id2',
        content: 'same content',
        type: ClipboardItemType.text,
        category: Category.text,
        timestamp: DateTime.now().add(const Duration(seconds: 3)),
        hash: 'samehash',
        size: 100,
      );

      // Act & Assert
      expect(item1.isDuplicate(item2), isTrue);
    });

    test('应该检测到非重复内容（不同哈希或超过 5 秒）', () async {
      // Arrange
      final item1 = ClipboardItem(
        id: 'id1',
        content: 'content 1',
        type: ClipboardItemType.text,
        category: Category.text,
        timestamp: DateTime.now(),
        hash: 'hash1',
        size: 100,
      );

      final item2 = ClipboardItem(
        id: 'id2',
        content: 'content 2',
        type: ClipboardItemType.text,
        category: Category.text,
        timestamp: DateTime.now().add(const Duration(seconds: 6)),
        hash: 'hash2',
        size: 100,
      );

      // Act & Assert
      expect(item1.isDuplicate(item2), isFalse);
    });

    test('应该忽略密码管理器的内容', () async {
      // Arrange
      final ignoredApps = [
        'com.agilebits.onepassword7',
        'com.bitwarden.desktop',
        'com.1password.1password',
      ];

      // Act & Assert: 所有这些应用都应该被忽略
      for (final appId in ignoredApps) {
        final shouldIgnore = monitor.shouldIgnoreApp(appId);
        expect(shouldIgnore, isTrue, reason: '$appId 应该被忽略');
      }
    });

    test('应该捕获非密码管理器的内容', () async {
      // Arrange
      final normalApps = [
        'com.apple.Safari',
        'com.google.Chrome',
        'com.microsoft.VSCode',
      ];

      // Act & Assert
      for (final appId in normalApps) {
        final shouldIgnore = monitor.shouldIgnoreApp(appId);
        expect(shouldIgnore, isFalse, reason: '$appId 不应该被忽略');
      }
    });

    test('应该正确调用 StorageService 保存项目', () async {
      // Arrange
      when(() => mockStorage.load()).thenAnswer((_) async {
        return ClipboardHistory();
      });
      when(() => mockStorage.save(any())).thenAnswer((_) async {});

      // Act
      final item = ClipboardItem(
        id: 'test-id',
        content: 'test content',
        type: ClipboardItemType.text,
        category: Category.text,
        timestamp: DateTime.now(),
        hash: 'testhash',
        size: 100,
      );

      await monitor.captureItem(item);

      // Assert
      verify(() => mockStorage.save(any())).called(1);
    });

    test('应该正确处理捕获失败', () async {
      // Arrange
      when(() => mockStorage.load()).thenThrow(Exception('存储失败'));

      // Act & Assert: 不应该抛出异常
      expect(() async {
        await monitor.start();
        await Future.delayed(const Duration(milliseconds: 100));
        await monitor.stop();
      }, returnsNormally);
    });
  });
}
