import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/models/clipboard_item.dart';
import 'package:paste_manager/models/category.dart';
import 'package:paste_manager/models/clipboard_history.dart';
import 'package:paste_manager/services/clipboard_monitor.dart';
import 'package:paste_manager/services/storage_service.dart';

void main() {
  group('剪贴板捕获延迟性能测试', () {
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

    testWidgets('剪贴板捕获延迟应该 <100ms（100 次操作平均）',
        (WidgetTester tester) async {
      // Arrange
      const testRuns = 100;
      final latencies = <Duration>[];

      await monitor.start();

      // Act: 测量 100 次捕获操作的延迟
      for (int i = 0; i < testRuns; i++) {
        final item = ClipboardItem(
          id: 'test-$i',
          content: 'Test content $i',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.now(),
          hash: 'hash-$i',
          size: 100,
        );

        final startTime = DateTime.now();
        await monitor.captureItem(item);
        final endTime = DateTime.now();

        latencies.add(endTime.difference(startTime));
      }

      await monitor.stop();

      // Assert: 计算平均延迟
      final totalLatency = latencies.fold(
        Duration.zero,
        (sum, duration) => sum + duration,
      );
      final averageLatency = totalLatency ~/ testRuns;

      print('平均捕获延迟: ${averageLatency.inMilliseconds}ms');
      print('最大延迟: ${latencies.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b)}ms');
      print('最小延迟: ${latencies.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b)}ms');

      expect(averageLatency.inMilliseconds, lessThan(100),
        reason: '平均延迟应该 <100ms');
    });

    testWidgets('1000 条历史记录时捕获延迟应该仍然 <100ms',
        (WidgetTester tester) async {
      // Arrange: 预填充 1000 条记录
      final items = List.generate(1000, (i) => ClipboardItem(
            id: 'existing-$i',
            content: 'Existing content $i',
            type: ClipboardItemType.text,
            category: Category.text,
            timestamp: DateTime.now(),
            hash: 'hash-$i',
            size: 100,
          ));

      final history = ClipboardHistory(initialItems: items);
      await storageService.save(history);

      // Act
      final latencies = <Duration>[];
      const testRuns = 100;

      await monitor.start();

      for (int i = 0; i < testRuns; i++) {
        final item = ClipboardItem(
          id: 'test-$i',
          content: 'New content $i',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.now(),
          hash: 'hash-new-$i',
          size: 100,
        );

        final startTime = DateTime.now();
        await monitor.captureItem(item);
        final endTime = DateTime.now();

        latencies.add(endTime.difference(startTime));
      }

      await monitor.stop();

      // Assert
      final totalLatency = latencies.fold(
        Duration.zero,
        (sum, duration) => sum + duration,
      );
      final averageLatency = totalLatency ~/ testRuns;

      print('1000 条历史时平均捕获延迟: ${averageLatency.inMilliseconds}ms');

      expect(averageLatency.inMilliseconds, lessThan(100),
        reason: '即使有 1000 条历史，捕获延迟也应该 <100ms');
    });

    testWidgets('应该正确处理存储限制达到时的情况',
        (WidgetTester tester) async {
      // Arrange: 创建 1000 条记录的历史
      final existingItems = List.generate(1000, (i) => ClipboardItem(
            id: 'existing-$i',
            content: 'Existing $i',
            type: ClipboardItemType.text,
            category: Category.text,
            timestamp: DateTime.now(),
            hash: 'hash-$i',
            size: 100 * 1024, // 100KB each
          ));

      final history = ClipboardHistory(
        initialItems: existingItems,
        maxSize: 100 * 1024 * 1024, // 100MB
      );
      await storageService.save(history);

      await monitor.start();

      // Act: 尝试添加新项目（应该移除最旧项目）
      final newItem = ClipboardItem(
        id: 'new-item',
        content: 'New content',
        type: ClipboardItemType.text,
        category: Category.text,
        timestamp: DateTime.now(),
        hash: 'newhash',
        size: 100 * 1024,
      );

      final startTime = DateTime.now();
      await monitor.captureItem(newItem);
      final latency = DateTime.now().difference(startTime);

      await monitor.stop();

      // Assert
      final updatedHistory = await storageService.load();
      expect(updatedHistory.totalCount, lessThanOrEqualTo(1000),
        reason: '不应该超过最大项目数');

      expect(latency.inMilliseconds, lessThan(100),
        reason: '即使处理限制强制执行，延迟也应该 <100ms');

      // 验证最旧项目被移除
      expect(
        updatedHistory.items.any((item) => item.id == 'existing-0'),
        isFalse,
        reason: '最旧的项目应该被移除',
      );
    });
  });
}
