import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paste_manager/models/clipboard_item.dart';
import 'package:paste_manager/services/storage_service.dart';
import 'package:paste_manager/services/clipboard_monitor.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('端到端分类工作流集成测试', () {
    late ClipboardMonitor monitor;
    late StorageService storageService;

    setUp(() async {
      storageService = StorageService();
      await storageService.clear();
      monitor = ClipboardMonitor(storageService: storageService);
    });

    tearDown(() async {
      await monitor.stop();
      await storageService.clear();
    });

    testWidgets('应该捕获URL并正确分类为link', (WidgetTester tester) async {
      // Arrange
      const testUrl = 'https://github.com/flutter/flutter';
      final item = ClipboardItem(
        id: 'test-url-1',
        content: testUrl,
        type: ClipboardItemType.url,
        categoryId: 'link',
        timestamp: DateTime.now(),
        hash: 'url-hash-123',
        size: testUrl.length,
      );

      // Act
      await monitor.captureItem(item);

      // Assert
      final history = await storageService.load();
      expect(history.totalCount, greaterThan(0));

      final linkItems = history.filterByCategoryId('link');
      expect(linkItems.isNotEmpty, isTrue, reason: '应该有链接分类的项目');
      expect(linkItems.first.content, testUrl);
      expect(linkItems.first.categoryId, 'link');
    });

    testWidgets('应该捕获文件路径并正确分类为file', (WidgetTester tester) async {
      // Arrange
      const testPath = '/Users/username/Documents/project/lib/main.dart';
      final item = ClipboardItem(
        id: 'test-file-1',
        content: testPath,
        type: ClipboardItemType.file,
        categoryId: 'file',
        timestamp: DateTime.now(),
        hash: 'file-hash-456',
        size: testPath.length,
      );

      // Act
      await monitor.captureItem(item);

      // Assert
      final history = await storageService.load();
      final fileItems = history.filterByCategoryId('file');
      expect(fileItems.isNotEmpty, isTrue, reason: '应该有文件分类的项目');
      expect(fileItems.first.content, testPath);
      expect(fileItems.first.categoryId, 'file');
    });

    testWidgets('应该捕获代码片段并正确分类为code', (WidgetTester tester) async {
      // Arrange
      const testCode = 'function helloWorld() {\n  console.log("Hello, World!");\n}';
      final item = ClipboardItem(
        id: 'test-code-1',
        content: testCode,
        type: ClipboardItemType.text,
        categoryId: 'code',
        timestamp: DateTime.now(),
        hash: 'code-hash-789',
        size: testCode.length,
      );

      // Act
      await monitor.captureItem(item);

      // Assert
      final history = await storageService.load();
      final codeItems = history.filterByCategoryId('code');
      expect(codeItems.isNotEmpty, isTrue, reason: '应该有代码分类的项目');
      expect(codeItems.first.content, testCode);
      expect(codeItems.first.categoryId, 'code');
    });

    testWidgets('应该捕获纯文本并正确分类为text', (WidgetTester tester) async {
      // Arrange
      const testText = 'This is a simple text message without any special patterns.';
      final item = ClipboardItem(
        id: 'test-text-1',
        content: testText,
        type: ClipboardItemType.text,
        categoryId: 'text',
        timestamp: DateTime.now(),
        hash: 'text-hash-abc',
        size: testText.length,
      );

      // Act
      await monitor.captureItem(item);

      // Assert
      final history = await storageService.load();
      final textItems = history.filterByCategoryId('text');
      expect(textItems.isNotEmpty, isTrue, reason: '应该有文本分类的项目');
      expect(textItems.first.content, testText);
      expect(textItems.first.categoryId, 'text');
    });

    testWidgets('应该正确处理混合内容并按优先级分类', (WidgetTester tester) async {
      // Arrange: URL优先级高于代码
      const mixedContent = 'Visit https://example.com for more info on function test() { }';
      final item = ClipboardItem(
        id: 'test-mixed-1',
        content: mixedContent,
        type: ClipboardItemType.url,
        categoryId: 'link',
        timestamp: DateTime.now(),
        hash: 'mixed-hash-1',
        size: mixedContent.length,
      );

      // Act
      await monitor.captureItem(item);

      // Assert
      final history = await storageService.load();
      final linkItems = history.filterByCategoryId('link');
      expect(linkItems.isNotEmpty, isTrue);
      expect(linkItems.first.categoryId, 'link');
    });

    testWidgets('应该验证所有4种分类都能被正确捕获', (WidgetTester tester) async {
      // Arrange: 创建所有4种类型的项目
      final items = [
        ClipboardItem(
          id: 'url-item',
          content: 'https://example.com',
          type: ClipboardItemType.url,
          categoryId: 'link',
          timestamp: DateTime.now(),
          hash: 'hash-1',
          size: 18,
        ),
        ClipboardItem(
          id: 'file-item',
          content: '/Users/test/file.txt',
          type: ClipboardItemType.file,
          categoryId: 'file',
          timestamp: DateTime.now().add(const Duration(seconds: 1)),
          hash: 'hash-2',
          size: 19,
        ),
        ClipboardItem(
          id: 'code-item',
          content: 'function test() { return; }',
          type: ClipboardItemType.text,
          categoryId: 'code',
          timestamp: DateTime.now().add(const Duration(seconds: 2)),
          hash: 'hash-3',
          size: 27,
        ),
        ClipboardItem(
          id: 'text-item',
          content: 'Just a plain text message.',
          type: ClipboardItemType.text,
          categoryId: 'text',
          timestamp: DateTime.now().add(const Duration(seconds: 3)),
          hash: 'hash-4',
          size: 25,
        ),
      ];

      // Act
      for (final item in items) {
        await monitor.captureItem(item);
      }

      // Assert: 验证所有4种分类都存在
      final history = await storageService.load();
      expect(history.totalCount, greaterThanOrEqualTo(4));

      final categories = ['link', 'file', 'code', 'text'];
      for (final categoryId in categories) {
        final itemsByCategory = history.filterByCategoryId(categoryId);
        expect(
          itemsByCategory.isNotEmpty,
          isTrue,
          reason: '应该有 $categoryId 分类的项目',
        );
      }
    });

    testWidgets('应该保持分类元数据在持久化后正确', (WidgetTester tester) async {
      // Arrange
      const testUrl = 'https://github.com/test/repo';
      final originalItem = ClipboardItem(
        id: 'persist-test',
        content: testUrl,
        type: ClipboardItemType.url,
        categoryId: 'link',
        timestamp: DateTime.now(),
        hash: 'persist-hash',
        size: testUrl.length,
      );

      // Act: 保存并重新加载
      await monitor.captureItem(originalItem);
      final history = await storageService.load();

      // Assert: 验证分类元数据正确保存和加载
      final savedItem = history.items.firstWhere((item) => item.id == 'persist-test');
      expect(savedItem.categoryId, 'link');
      expect(savedItem.type, ClipboardItemType.url);

      // 验证JSON序列化
      final json = savedItem.toJson();
      expect(json['categoryId'], 'link');
      expect(json['type'], 'url');
    });

    testWidgets('应该按分类正确过滤历史记录', (WidgetTester tester) async {
      // Arrange
      final items = [
        // 10个链接
        for (int i = 0; i < 10; i++)
          ClipboardItem(
            id: 'link-$i',
            content: 'https://example.com/$i',
            type: ClipboardItemType.url,
            categoryId: 'link',
            timestamp: DateTime.now().add(Duration(seconds: i)),
            hash: 'hash-link-$i',
            size: 20,
          ),
        // 5个代码
        for (int i = 0; i < 5; i++)
          ClipboardItem(
            id: 'code-$i',
            content: 'function test$i() { }',
            type: ClipboardItemType.text,
            categoryId: 'code',
            timestamp: DateTime.now().add(Duration(seconds: 10 + i)),
            hash: 'hash-code-$i',
            size: 20,
          ),
      ];

      // Act
      for (final item in items) {
        await monitor.captureItem(item);
      }

      // Assert
      final history = await storageService.load();
      expect(history.totalCount, 15);

      final linkItems = history.filterByCategoryId('link');
      final codeItems = history.filterByCategoryId('code');
      final textItems = history.filterByCategoryId('text');

      expect(linkItems.length, 10, reason: '应该有10个链接项目');
      expect(codeItems.length, 5, reason: '应该有5个代码项目');
      expect(textItems.isEmpty, isTrue, reason: '不应该有纯文本项目');
    });

    testWidgets('应该支持混合复制场景（URL→文件→代码→文本）', (WidgetTester tester) async {
      // Arrange: 模拟用户连续复制不同类型的内容
      final items = [
        ClipboardItem(
          id: 'seq-1',
          content: 'https://github.com',
          type: ClipboardItemType.url,
          categoryId: 'link',
          timestamp: DateTime.now(),
          hash: 'seq-1',
          size: 17,
        ),
        ClipboardItem(
          id: 'seq-2',
          content: '/Users/username/project',
          type: ClipboardItemType.file,
          categoryId: 'file',
          timestamp: DateTime.now().add(const Duration(seconds: 1)),
          hash: 'seq-2',
          size: 22,
        ),
        ClipboardItem(
          id: 'seq-3',
          content: 'function main() { return 0; }',
          type: ClipboardItemType.text,
          categoryId: 'code',
          timestamp: DateTime.now().add(const Duration(seconds: 2)),
          hash: 'seq-3',
          size: 30,
        ),
        ClipboardItem(
          id: 'seq-4',
          content: 'Meeting notes from today',
          type: ClipboardItemType.text,
          categoryId: 'text',
          timestamp: DateTime.now().add(const Duration(seconds: 3)),
          hash: 'seq-4',
          size: 25,
        ),
      ];

      // Act
      for (final item in items) {
        await monitor.captureItem(item);
      }

      // Assert: 验证时间顺序和分类
      final history = await storageService.load();
      expect(history.totalCount, 4);

      // 验证顺序（最新的在前）
      expect(history.items[0].id, 'seq-4');
      expect(history.items[0].categoryId, 'text');
      expect(history.items[1].id, 'seq-3');
      expect(history.items[1].categoryId, 'code');
      expect(history.items[2].id, 'seq-2');
      expect(history.items[2].categoryId, 'file');
      expect(history.items[3].id, 'seq-1');
      expect(history.items[3].categoryId, 'link');
    });
  });
}
