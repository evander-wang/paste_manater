import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/services/command_service.dart';
import 'package:paste_manager/services/storage_service.dart';
import 'package:paste_manager/models/command.dart';
import 'package:paste_manager/models/clipboard_item.dart';
import 'package:paste_manager/models/category.dart';

/// 置顶功能性能验证测试
///
/// 验证 SC-003, SC-004, SC-007 性能要求
void main() {
  // 初始化 Flutter 测试绑定
  TestWidgetsFlutterBinding.ensureInitialized();

  group('置顶功能性能验证', () {
    late CommandService commandService;
    late StorageService storageService;

    setUp(() async {
      commandService = CommandService();
      await commandService.initialize();

      storageService = StorageService();
    });

    group('T060: 置顶/取消置顶操作性能 (SC-003)', () {
      test('Command置顶操作应该在500ms内完成', () async {
        // Arrange
        final testCommand = Command(
          id: 'perf-test-1',
          name: '性能测试命令',
          command: 'echo "performance test"',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        // Act - 测量置顶操作时间
        final stopwatch = Stopwatch()..start();
        await commandService.pinCommand(testCommand.id);
        stopwatch.stop();

        // Assert
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(500),
          reason: '置顶操作应在500ms内完成,实际耗时: ${stopwatch.elapsedMilliseconds}ms',
        );

        // Cleanup
        await commandService.unpinCommand(testCommand.id);
      });

      test('Command取消置顶操作应该在500ms内完成', () async {
        // Arrange
        final testCommand = Command(
          id: 'perf-test-2',
          name: '性能测试命令2',
          command: 'echo "unpin test"',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );
        await commandService.pinCommand(testCommand.id);

        // Act - 测量取消置顶操作时间
        final stopwatch = Stopwatch()..start();
        await commandService.unpinCommand(testCommand.id);
        stopwatch.stop();

        // Assert
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(500),
          reason: '取消置顶操作应在500ms内完成,实际耗时: ${stopwatch.elapsedMilliseconds}ms',
        );
      });

      test('ClipboardItem置顶操作应该在500ms内完成', () async {
        // Arrange - 创建测试数据
        final testItem = ClipboardItem(
          id: 'perf-test-item-1',
          content: '性能测试剪贴板内容',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.now(),
          hash: 'perftest123',
          size: 50,
        );

        // 保存测试项
        final history = await storageService.load();
        final updatedHistory = history.add(testItem);
        await storageService.save(updatedHistory);

        // Act - 测量置顶操作时间
        final stopwatch = Stopwatch()..start();
        await storageService.pinItem(testItem.id);
        stopwatch.stop();

        // Assert
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(500),
          reason: '剪贴板项置顶操作应在500ms内完成,实际耗时: ${stopwatch.elapsedMilliseconds}ms',
        );

        // Cleanup
        await storageService.unpinItem(testItem.id);
      });

      test('ClipboardItem取消置顶操作应该在500ms内完成', () async {
        // Arrange
        final testItem = ClipboardItem(
          id: 'perf-test-item-2',
          content: '取消置顶性能测试',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.now(),
          hash: 'perftest456',
          size: 50,
        );

        final history = await storageService.load();
        final updatedHistory = history.add(testItem);
        await storageService.save(updatedHistory);
        await storageService.pinItem(testItem.id);

        // Act - 测量取消置顶操作时间
        final stopwatch = Stopwatch()..start();
        await storageService.unpinItem(testItem.id);
        stopwatch.stop();

        // Assert
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(500),
          reason: '剪贴板项取消置顶操作应在500ms内完成,实际耗时: ${stopwatch.elapsedMilliseconds}ms',
        );
      });
    });

    group('T062: 置顶状态持久化率 (SC-007)', () {
      test('Command置顶状态应该100%持久化', () async {
        // Arrange
        final testCommand = Command(
          id: 'persistence-test-1',
          name: '持久化测试命令',
          command: 'echo "persistence"',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        // Act - 置顶命令
        await commandService.pinCommand(testCommand.id);

        // 重新加载服务
        await commandService.initialize();

        // Assert - 验证置顶状态被持久化
        final reloaded = commandService.currentCommands.firstWhere(
          (cmd) => cmd.id == testCommand.id,
          orElse: () => throw Exception('命令未找到'),
        );

        expect(
          reloaded.isPinned,
          isTrue,
          reason: '置顶状态应该被持久化到存储',
        );
        expect(reloaded.pinnedAt, isNotNull, reason: '置顶时间应该被保存');

        // Cleanup
        await commandService.unpinCommand(testCommand.id);
      });

      test('Command取消置顶状态应该100%持久化', () async {
        // Arrange
        final testCommand = Command(
          id: 'persistence-test-2',
          name: '持久化测试命令2',
          command: 'echo "unpin persistence"',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        // 先置顶
        await commandService.pinCommand(testCommand.id);

        // Act - 取消置顶
        await commandService.unpinCommand(testCommand.id);

        // 重新加载服务
        await commandService.initialize();

        // Assert - 验证取消置顶状态被持久化
        final reloaded = commandService.currentCommands.firstWhere(
          (cmd) => cmd.id == testCommand.id,
          orElse: () => throw Exception('命令未找到'),
        );

        expect(
          reloaded.isPinned,
          isFalse,
          reason: '取消置顶状态应该被持久化到存储',
        );
        expect(reloaded.pinnedAt, isNull, reason: '置顶时间应该被清除');
      });

      test('ClipboardItem置顶状态应该100%持久化', () async {
        // Arrange
        final testItem = ClipboardItem(
          id: 'persistence-item-1',
          content: '持久化测试内容',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.now(),
          hash: 'persist123',
          size: 30,
        );

        // 添加并置顶
        var history = await storageService.load();
        history = history.add(testItem);
        await storageService.save(history);
        await storageService.pinItem(testItem.id);

        // Act - 重新加载
        history = await storageService.load();
        final reloaded = history.items.firstWhere(
          (item) => item.id == testItem.id,
          orElse: () => throw Exception('项目未找到'),
        );

        // Assert
        expect(
          reloaded.isPinned,
          isTrue,
          reason: '剪贴板项置顶状态应该被持久化',
        );
        expect(reloaded.pinnedAt, isNotNull, reason: '置顶时间应该被保存');

        // Cleanup
        await storageService.unpinItem(testItem.id);
      });

      test('ClipboardItem取消置顶状态应该100%持久化', () async {
        // Arrange
        final testItem = ClipboardItem(
          id: 'persistence-item-2',
          content: '取消置顶持久化测试',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.now(),
          hash: 'persist456',
          size: 30,
        );

        // 添加、置顶、取消置顶
        var history = await storageService.load();
        history = history.add(testItem);
        await storageService.save(history);
        await storageService.pinItem(testItem.id);
        await storageService.unpinItem(testItem.id);

        // Act - 重新加载
        history = await storageService.load();
        final reloaded = history.items.firstWhere(
          (item) => item.id == testItem.id,
          orElse: () => throw Exception('项目未找到'),
        );

        // Assert
        expect(
          reloaded.isPinned,
          isFalse,
          reason: '剪贴板项取消置顶状态应该被持久化',
        );
        expect(reloaded.pinnedAt, isNull, reason: '置顶时间应该被清除');
      });

      test('多次置顶/取消置顶循环后状态应该正确持久化', () async {
        // Arrange
        final testCommand = Command(
          id: 'persistence-cycle-1',
          name: '循环持久化测试',
          command: 'echo "cycle test"',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        // Act - 执行多次置顶/取消置顶循环
        for (int i = 0; i < 5; i++) {
          await commandService.pinCommand(testCommand.id);
          await commandService.unpinCommand(testCommand.id);
        }

        // 最后置顶
        await commandService.pinCommand(testCommand.id);

        // 重新加载
        await commandService.initialize();

        // Assert
        final reloaded = commandService.currentCommands.firstWhere(
          (cmd) => cmd.id == testCommand.id,
          orElse: () => throw Exception('命令未找到'),
        );

        expect(
          reloaded.isPinned,
          isTrue,
          reason: '经过多次循环后置顶状态应该正确持久化',
        );

        // Cleanup
        await commandService.unpinCommand(testCommand.id);
      });
    });
  });
}
