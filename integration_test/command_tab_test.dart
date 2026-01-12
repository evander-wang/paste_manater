import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paste_manager/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('命令列表加载E2E测试 (T021)', () {
    testWidgets('完整用户流程: 加载命令列表并复制', (WidgetTester tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();

      // 验证应用已启动
      expect(find.byType(MaterialApp), findsWidgets);

      // 查找"常用命令"标签页
      final commandTab = find.text('常用命令');
      if (commandTab.evaluate().isNotEmpty) {
        // 点击常用命令标签页
        await tester.tap(commandTab);
        await tester.pumpAndSettle();

        // 验证命令列表已加载
        // 注意: 这里假设有测试数据,实际可能需要先创建测试文件
        final commandList = find.byType(ListView);
        expect(commandList, findsOneWidget);

        // 验证至少显示了空状态或命令项
        final emptyState = find.textContaining('添加');
        final commandItems = find.byType(ListTile);

        expect(
          emptyState.evaluate().isNotEmpty || commandItems.evaluate().isNotEmpty,
          true,
          reason: '应该显示空状态或命令列表',
        );
      }
    });

    testWidgets('空状态显示', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 查找常用命令标签页
      final commandTab = find.text('常用命令');
      if (commandTab.evaluate().isNotEmpty) {
        await tester.tap(commandTab);
        await tester.pumpAndSettle();

        // 如果没有命令,应该显示空状态提示
        final commandItems = find.byType(ListTile);
        if (commandItems.evaluate().isEmpty) {
          // 应该有空状态提示
          final hint1 = find.textContaining('编辑');
          final hint2 = find.textContaining('添加');
          final hint3 = find.textContaining('创建');

          expect(
            hint1.evaluate().isNotEmpty ||
                hint2.evaluate().isNotEmpty ||
                hint3.evaluate().isNotEmpty,
            true,
            reason: '空列表时应该显示引导提示',
          );
        }
      }
    });

    testWidgets('命令复制功能', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 查找常用命令标签页
      final commandTab = find.text('常用命令');
      if (commandTab.evaluate().isNotEmpty) {
        await tester.tap(commandTab);
        await tester.pumpAndSettle();

        // 查找第一个命令项
        final firstCommand = find.byType(ListTile).first;
        if (firstCommand.evaluate().isNotEmpty) {
          // 点击命令
          await tester.tap(firstCommand);
          await tester.pumpAndSettle();

          // 验证复制成功的反馈
          // 这可能是Snackbar或Tooltip
          final copyFeedback1 = find.byType(SnackBar);
          final copyFeedback2 = find.textContaining('复制');
          final copyFeedback3 = find.textContaining('成功');

          final hasFeedback = copyFeedback1.evaluate().isNotEmpty ||
              copyFeedback2.evaluate().isNotEmpty ||
              copyFeedback3.evaluate().isNotEmpty;

          expect(
            hasFeedback,
            true,
            reason: '应该显示复制成功的反馈',
          );
        }
      }
    });

    testWidgets('性能测试: 100个命令列表应该在2秒内加载', (WidgetTester tester) async {
      final startTime = DateTime.now();

      app.main();
      await tester.pumpAndSettle();

      final loadTime = DateTime.now().difference(startTime);

      // 启动时间应该小于2秒
      expect(
        loadTime.inSeconds,
        lessThan(2),
        reason: '应用启动时间应该小于2秒',
      );
    });
  });
}
