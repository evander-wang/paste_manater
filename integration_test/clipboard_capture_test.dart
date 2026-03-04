import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paste_manager/models/clipboard_item.dart';
import 'package:paste_manager/models/clipboard_history.dart';
import 'package:paste_manager/services/storage_service.dart';
import 'package:paste_manager/services/clipboard_monitor.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('剪贴板捕获工作流集成测试', () {
    late ClipboardMonitor monitor;
    late StorageService storageService;

    setUp(() async {
      storageService = StorageService();
      monitor = ClipboardMonitor(storageService: storageService);
      await storageService.clear(); // 确保从干净状态开始
    });

    tearDown(() async {
      await monitor.stop();
      await storageService.clear();
    });

    testWidgets('应该捕获文本内容并存储到历史', (WidgetTester tester) async {
      // Arrange: 启动监听
      await monitor.start();

      // Act: 模拟复制文本
      await tester.pumpAndSettle();
      // TODO: 模拟剪贴板复制操作

      // 等待捕获完成
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      // Assert: 验证项目被捕获
      final history = await storageService.load();
      expect(history.totalCount, greaterThan(0));

      final textItems = history.filterByCategoryId('text');
      expect(textItems.isNotEmpty, isTrue);
    });

    testWidgets('应该捕获 URL 并自动分类为链接', (WidgetTester tester) async {
      // Arrange
      await monitor.start();

      // Act: 模拟复制 URL
      await tester.pumpAndSettle();
      // TODO: 模拟 URL 复制操作

      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      // Assert
      final history = await storageService.load();
      final linkItems = history.filterByCategoryId('link');
      expect(linkItems.isNotEmpty, isTrue);
    });

    testWidgets('应该按时间倒序显示历史（最新的在前）', (WidgetTester tester) async {
      // Arrange
      await monitor.start();

      // Act: 连续复制多个项目
      await tester.pumpAndSettle();
      // TODO: 模拟复制 3 个不同项目

      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Assert
      final history = await storageService.load();
      expect(history.totalCount, greaterThanOrEqualTo(3));

      // 验证时间顺序（最新的在前）
      if (history.totalCount >= 2) {
        expect(
          history.items[0].timestamp.isAfter(history.items[1].timestamp),
          isTrue,
        );
      }
    });

    testWidgets('应该在历史满时移除最旧项目', (WidgetTester tester) async {
      // Arrange
      await monitor.start();

      // Act: 复制超过最大限制的项目
      await tester.pumpAndSettle();
      // TODO: 模拟复制 1001 个项目

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Assert
      final history = await storageService.load();
      expect(history.totalCount, lessThanOrEqualTo(1000)); // 不超过最大限制
    });

    testWidgets('应该跨应用重启持久化数据', (WidgetTester tester) async {
      // Arrange
      await monitor.start();

      // Act: 复制项目
      await tester.pumpAndSettle();
      // TODO: 模拟复制操作

      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      // 停止监听并重新启动（模拟应用重启）
      await monitor.stop();
      await monitor.start();

      await tester.pumpAndSettle();

      // Assert: 数据应该仍然存在
      final history = await storageService.load();
      expect(history.totalCount, greaterThan(0));
    });
  });
}
