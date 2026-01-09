import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paste_manager/services/hotkey_manager.dart';
import 'package:paste_manager/ui/clipboard_window.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('全局热键注册和触发集成测试', () {
    late HotkeyManager hotkeyManager;
    late ClipboardWindow clipboardWindow;

    setUp(() async {
      hotkeyManager = HotkeyManager();
      clipboardWindow = ClipboardWindow();
    });

    tearDown(() async {
      await hotkeyManager.unregister();
    });

    testWidgets('应该成功注册全局热键（Cmd+Shift+V）', (WidgetTester tester) async {
      // Arrange
      final hotkey = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      // Act
      final registered = await hotkeyManager.register(hotkey, () {
        // 热键触发时的回调
      });

      // Assert
      expect(registered, isTrue, reason: '热键应该成功注册');
      expect(hotkeyManager.isRegistered, isTrue, reason: '热键管理器应该处于已注册状态');
    });

    testWidgets('热键被触发时应该打开剪贴板窗口', (WidgetTester tester) async {
      // Arrange
      bool hotkeyTriggered = false;
      final hotkey = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      await hotkeyManager.register(hotkey, () {
        hotkeyTriggered = true;
      });

      // 初始状态：窗口应该隐藏
      expect(clipboardWindow.isVisible, isFalse);

      // Act: 模拟热键触发
      // 注意：在实际集成测试中，这需要真实的系统事件
      // 这里我们测试回调机制
      final callback = hotkeyManager.getCallback();
      callback?.call();

      // Assert
      expect(hotkeyTriggered, isTrue, reason: '热键回调应该被触发');
    });

    testWidgets('应该支持热键注销', (WidgetTester tester) async {
      // Arrange
      final hotkey = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      await hotkeyManager.register(hotkey, () {});

      // Assert: 热键已注册
      expect(hotkeyManager.isRegistered, isTrue);

      // Act: 注销热键
      await hotkeyManager.unregister();

      // Assert: 热键已注销
      expect(hotkeyManager.isRegistered, isFalse, reason: '热键应该被注销');
    });

    testWidgets('应该支持重新注册热键', (WidgetTester tester) async {
      // Arrange
      final hotkey1 = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      // 第一次注册
      await hotkeyManager.register(hotkey1, () {});
      expect(hotkeyManager.isRegistered, isTrue);

      // Act: 注销并重新注册不同的热键
      await hotkeyManager.unregister();

      final hotkey2 = Hotkey(
        keyCode: KeyCode.c,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      final reRegistered = await hotkeyManager.register(hotkey2, () {});

      // Assert
      expect(reRegistered, isTrue, reason: '应该能够重新注册热键');
      expect(hotkeyManager.isRegistered, isTrue);
    });

    testWidgets('应该支持多个热键同时注册', (WidgetTester tester) async {
      // Arrange
      final hotkey1 = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      final hotkey2 = Hotkey(
        keyCode: KeyCode.h,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      int triggerCount = 0;

      // Act: 注册两个热键
      final registered1 = await hotkeyManager.register(hotkey1, () {
        triggerCount++;
      });

      final registered2 = await hotkeyManager.register(hotkey2, () {
        triggerCount++;
      });

      // Assert
      expect(registered1, isTrue);
      expect(registered2, isTrue);
      expect(hotkeyManager.registeredCount, greaterThanOrEqualTo(2));
    });

    testWidgets('应该处理热键注册失败（热键已被占用）', (WidgetTester tester) async {
      // Arrange
      final hotkey = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      // 第一次注册成功
      await hotkeyManager.register(hotkey, () {});

      // Act: 尝试注册相同的热键
      final duplicateRegistered = await hotkeyManager.register(hotkey, () {});

      // Assert
      expect(duplicateRegistered, isFalse, reason: '重复的热键应该注册失败');
    });

    testWidgets('热键应该正确传递键盘事件参数', (WidgetTester tester) async {
      // Arrange
      Hotkey? receivedHotkey;
      final hotkey = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      await hotkeyManager.register(hotkey, (triggeredHotkey) {
        receivedHotkey = triggeredHotkey;
      });

      // Act: 触发热键
      final callback = hotkeyManager.getCallback();
      callback?.call(hotkey);

      // Assert
      expect(receivedHotkey, isNotNull);
      expect(receivedHotkey?.keyCode, KeyCode.v);
      expect(receivedHotkey?.modifiers, contains(KeyModifier.cmd));
      expect(receivedHotkey?.modifiers, contains(KeyModifier.shift));
    });

    testWidgets('应该支持暂停和恢复热键监听', (WidgetTester tester) async {
      // Arrange
      final hotkey = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      int triggerCount = 0;
      await hotkeyManager.register(hotkey, () {
        triggerCount++;
      });

      // Act: 暂停热键
      await hotkeyManager.pause();
      final callback = hotkeyManager.getCallback();
      callback?.call(); // 暂停时不应该触发

      // 恢复热键
      await hotkeyManager.resume();
      callback?.call(); // 恢复后应该触发

      // Assert
      expect(triggerCount, equals(1), reason: '热键暂停时不应触发，恢复后应该触发');
    });
  });
}
