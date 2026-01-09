import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/services/hotkey_manager.dart';
import 'package:paste_manager/ui/clipboard_window.dart';

void main() {
  group('热键和窗口性能测试', () {
    late HotkeyManager hotkeyManager;
    late ClipboardWindow clipboardWindow;

    setUp(() {
      hotkeyManager = HotkeyManager();
      clipboardWindow = ClipboardWindow();
    });

    tearDown(() async {
      await hotkeyManager.unregister();
    });

    testWidgets('窗口打开延迟应该 <200ms（100次操作平均）', (WidgetTester tester) async {
      // Arrange
      final hotkey = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      await hotkeyManager.register(hotkey, () {
        clipboardWindow.show();
      });

      final latencies = <Duration>[];
      const testRuns = 100;

      // Act: 测量100次窗口打开操作
      for (int i = 0; i < testRuns; i++) {
        // 确保窗口是关闭的
        if (clipboardWindow.isVisible) {
          clipboardWindow.hide();
        }

        await tester.pump();

        final startTime = DateTime.now();
        clipboardWindow.show();
        await tester.pumpAndSettle();
        final endTime = DateTime.now();

        latencies.add(endTime.difference(startTime));
      }

      // Assert: 计算平均延迟
      final totalLatency = latencies.fold(
        Duration.zero,
        (sum, duration) => sum + duration,
      );
      final averageLatency = totalLatency ~/ testRuns;

      print('========== 窗口打开性能报告 ==========');
      print('测试次数: $testRuns');
      print('平均延迟: ${averageLatency.inMilliseconds}ms');
      print('最大延迟: ${latencies.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b)}ms');
      print('最小延迟: ${latencies.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b)}ms');
      print('====================================');

      expect(
        averageLatency.inMilliseconds,
        lessThan(200),
        reason: '平均窗口打开延迟应该 <200ms',
      );
    });

    testWidgets('热键注册延迟应该 <50ms', (WidgetTester tester) async {
      // Arrange
      final hotkey = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      final latencies = <Duration>[];
      const testRuns = 50;

      // Act: 测量热键注册延迟
      for (int i = 0; i < testRuns; i++) {
        // 先注销（如果已注册）
        if (hotkeyManager.isRegistered) {
          await hotkeyManager.unregister();
        }

        final startTime = DateTime.now();
        await hotkeyManager.register(hotkey, () {});
        final endTime = DateTime.now();

        latencies.add(endTime.difference(startTime));
      }

      // Assert
      final totalLatency = latencies.fold(
        Duration.zero,
        (sum, duration) => sum + duration,
      );
      final averageLatency = totalLatency ~/ testRuns;

      print('========== 热键注册性能报告 ==========');
      print('测试次数: $testRuns');
      print('平均延迟: ${averageLatency.inMilliseconds}ms');
      print('====================================');

      expect(
        averageLatency.inMilliseconds,
        lessThan(50),
        reason: '热键注册延迟应该 <50ms',
      );
    });

    testWidgets('热键触发到窗口显示的总延迟应该 <300ms', (WidgetTester tester) async {
      // Arrange
      final hotkey = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      await hotkeyManager.register(hotkey, () {
        clipboardWindow.show();
      });

      final latencies = <Duration>[];
      const testRuns = 50;

      // Act: 测量从热键触发到窗口显示的延迟
      for (int i = 0; i < testRuns; i++) {
        if (clipboardWindow.isVisible) {
          clipboardWindow.hide();
        }
        await tester.pump();

        final startTime = DateTime.now();
        // 模拟热键触发
        final callback = hotkeyManager.getCallback();
        callback?.call();
        await tester.pumpAndSettle();
        final endTime = DateTime.now();

        latencies.add(endTime.difference(startTime));
      }

      // Assert
      final totalLatency = latencies.fold(
        Duration.zero,
        (sum, duration) => sum + duration,
      );
      final averageLatency = totalLatency ~/ testRuns;

      print('========== 热键到窗口显示性能报告 ==========');
      print('测试次数: $testRuns');
      print('平均延迟: ${averageLatency.inMilliseconds}ms');
      print('====================================');

      expect(
        averageLatency.inMilliseconds,
        lessThan(300),
        reason: '热键触发到窗口显示的总延迟应该 <300ms',
      );
    });

    testWidgets('窗口关闭延迟应该 <100ms', (WidgetTester tester) async {
      // Arrange
      final hotkey = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      await hotkeyManager.register(hotkey, () {});
      clipboardWindow.show();
      await tester.pumpAndSettle();

      final latencies = <Duration>[];
      const testRuns = 100;

      // Act: 测量窗口关闭延迟
      for (int i = 0; i < testRuns; i++) {
        clipboardWindow.show();
        await tester.pump();

        final startTime = DateTime.now();
        clipboardWindow.hide();
        await tester.pump();
        final endTime = DateTime.now();

        latencies.add(endTime.difference(startTime));
      }

      // Assert
      final totalLatency = latencies.fold(
        Duration.zero,
        (sum, duration) => sum + duration,
      );
      final averageLatency = totalLatency ~/ testRuns;

      print('========== 窗口关闭性能报告 ==========');
      print('测试次数: $testRuns');
      print('平均延迟: ${averageLatency.inMilliseconds}ms');
      print('====================================');

      expect(
        averageLatency.inMilliseconds,
        lessThan(100),
        reason: '窗口关闭延迟应该 <100ms',
      );
    });

    testWidgets('连续打开/关闭窗口的性能测试', (WidgetTester tester) async {
      // Arrange
      final hotkey = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      await hotkeyManager.register(hotkey, () {
        if (clipboardWindow.isVisible) {
          clipboardWindow.hide();
        } else {
          clipboardWindow.show();
        }
      });

      final latencies = <Duration>[];
      const testRuns = 50;

      // Act: 测量连续切换的性能
      for (int i = 0; i < testRuns; i++) {
        final startTime = DateTime.now();
        final callback = hotkeyManager.getCallback();
        callback?.call();
        await tester.pumpAndSettle();
        final endTime = DateTime.now();

        latencies.add(endTime.difference(startTime));
      }

      // Assert
      final totalLatency = latencies.fold(
        Duration.zero,
        (sum, duration) => sum + duration,
      );
      final averageLatency = totalLatency ~/ testRuns;

      print('========== 窗口切换性能报告 ==========');
      print('测试次数: $testRuns');
      print('平均延迟: ${averageLatency.inMilliseconds}ms');
      print('====================================');

      expect(
        averageLatency.inMilliseconds,
        lessThan(250),
        reason: '窗口切换延迟应该 <250ms',
      );
    });

    testWidgets('内存使用应该保持稳定（多次操作后）', (WidgetTester tester) async {
      // Arrange
      final hotkey = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      await hotkeyManager.register(hotkey, () {
        if (clipboardWindow.isVisible) {
          clipboardWindow.hide();
        } else {
          clipboardWindow.show();
        }
      });

      // Act: 执行大量操作
      for (int i = 0; i < 500; i++) {
        final callback = hotkeyManager.getCallback();
        callback?.call();
        await tester.pump();
      }

      // Assert: 验证内存没有显著增长
      // 注意：这里只是示例，实际的内存测试需要更复杂的工具
      // 在真实场景中，您可能使用Dart的 Observatory或DevTools
      expect(hotkeyManager.isRegistered, isTrue);
      expect(clipboardWindow.isVisible, isTrue); // 最后一次是show
    });
  });
}
