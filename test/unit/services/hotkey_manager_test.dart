import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paste_manager/services/hotkey_manager.dart';
import 'package:paste_manager/services/storage_service.dart';

class MockStorageService extends Mock implements StorageService {}

void main() {
  group('HotkeyManager 热键冲突检测和自定义测试', () {
    late HotkeyManager hotkeyManager;
    late MockStorageService mockStorage;

    setUp(() {
      mockStorage = MockStorageService();
      hotkeyManager = HotkeyManager(storageService: mockStorage);
    });

    tearDown(() async {
      await hotkeyManager.unregister();
    });

    test('应该检测热键冲突（相同的热键组合）', () {
      // Arrange
      final hotkey1 = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      final hotkey2 = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      // Act
      final hasConflict = hotkeyManager.hasConflict(hotkey1, hotkey2);

      // Assert
      expect(hasConflict, isTrue, reason: '相同的热键应该检测为冲突');
    });

    test('应该检测不同热键无冲突', () {
      // Arrange
      final hotkey1 = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      final hotkey2 = Hotkey(
        keyCode: KeyCode.c,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      // Act
      final hasConflict = hotkeyManager.hasConflict(hotkey1, hotkey2);

      // Assert
      expect(hasConflict, isFalse, reason: '不同的热键不应该冲突');
    });

    test('应该检测修饰键不同的热键无冲突', () {
      // Arrange
      final hotkey1 = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      final hotkey2 = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [KeyModifier.cmd, KeyModifier.option],
      );

      // Act
      final hasConflict = hotkeyManager.hasConflict(hotkey1, hotkey2);

      // Assert
      expect(hasConflict, isFalse, reason: '修饰键不同的热键不应该冲突');
    });

    test('应该支持用户自定义热键', () async {
      // Arrange
      final customHotkey = Hotkey(
        keyCode: KeyCode.h,
        modifiers: [KeyModifier.cmd, KeyModifier.option],
      );

      // Act
      final registered = await hotkeyManager.register(customHotkey, () {});

      // Assert
      expect(registered, isTrue, reason: '自定义热键应该成功注册');
      expect(hotkeyManager.currentHotkey?.keyCode, KeyCode.h);
      expect(hotkeyManager.currentHotkey?.modifiers, contains(KeyModifier.cmd));
      expect(hotkeyManager.currentHotkey?.modifiers, contains(KeyModifier.option));
    });

    test('应该保存用户自定义热键到存储', () async {
      // Arrange
      final customHotkey = Hotkey(
        keyCode: KeyCode.b,
        modifiers: [KeyModifier.cmd, KeyModifier.control],
      );

      when(() => mockStorage.save(any())).thenAnswer((_) async {});

      // Act
      await hotkeyManager.register(customHotkey, () {});
      await hotkeyManager.saveHotkeyPreference();

      // Assert
      verify(() => mockStorage.save(any())).called(1);
    });

    test('应该从存储加载用户自定义热键', () async {
      // Arrange
      final savedHotkey = Hotkey(
        keyCode: KeyCode.k,
        modifiers: [KeyModifier.cmd],
      );

      when(() => mockStorage.load()).thenAnswer((_) async {
        // 模拟返回包含热键配置的历史
        return ClipboardHistory(initialItems: []);
      });

      // Act
      await hotkeyManager.loadHotkeyPreference();

      // Assert
      verify(() => mockStorage.load()).called(1);
    });

    test('应该验证热键组合的有效性', () {
      // Arrange
      final validHotkey = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [KeyModifier.cmd],
      );

      final invalidHotkey1 = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [], // 没有修饰键
      );

      final invalidHotkey2 = Hotkey(
        keyCode: KeyCode.unknown,
        modifiers: [KeyModifier.cmd], // 未知键
      );

      // Act & Assert
      expect(hotkeyManager.isValidHotkey(validHotkey), isTrue);
      expect(hotkeyManager.isValidHotkey(invalidHotkey1), isFalse);
      expect(hotkeyManager.isValidHotkey(invalidHotkey2), isFalse);
    });

    test('应该重置为默认热键（Cmd+Shift+V）', () async {
      // Arrange
      final customHotkey = Hotkey(
        keyCode: KeyCode.x,
        modifiers: [KeyModifier.cmd, KeyModifier.option],
      );

      await hotkeyManager.register(customHotkey, () {});

      // Act
      await hotkeyManager.resetToDefault();

      // Assert
      expect(hotkeyManager.currentHotkey?.keyCode, KeyCode.v);
      expect(hotkeyManager.currentHotkey?.modifiers, contains(KeyModifier.cmd));
      expect(hotkeyManager.currentHotkey?.modifiers, contains(KeyModifier.shift));
    });

    test('应该列出系统保留的热键（不应该被用户使用）', () {
      // Act
      final reservedHotkeys = hotkeyManager.getSystemReservedHotkeys();

      // Assert
      expect(reservedHotkeys, isNotEmpty);
      expect(
        reservedHotkeys.any((hotkey) =>
          hotkey.keyCode == KeyCode.q &&
          hotkey.modifiers.contains(KeyModifier.cmd)),
        isTrue,
        reason: 'Cmd+Q 应该在系统保留列表中',
      );
    });

    test('应该检查热键是否与系统保留热键冲突', () {
      // Arrange
      final systemHotkey = Hotkey(
        keyCode: KeyCode.q,
        modifiers: [KeyModifier.cmd],
      );

      // Act
      final isReserved = hotkeyManager.isSystemReserved(systemHotkey);

      // Assert
      expect(isReserved, isTrue, reason: '系统保留热键应该被检测为冲突');
    });

    test('应该支持热键组合的字符串表示', () {
      // Arrange
      final hotkey1 = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      final hotkey2 = Hotkey(
        keyCode: KeyCode.c,
        modifiers: [KeyModifier.cmd],
      );

      // Act
      final string1 = hotkeyManager.hotkeyToString(hotkey1);
      final string2 = hotkeyManager.hotkeyToString(hotkey2);

      // Assert
      expect(string1, contains('Cmd'));
      expect(string1, contains('Shift'));
      expect(string1, contains('V'));
      expect(string2, contains('Cmd'));
      expect(string2, contains('C'));
    });

    test('应该从字符串解析热键组合', () {
      // Arrange
      final hotkeyString = 'Cmd+Shift+V';

      // Act
      final parsedHotkey = hotkeyManager.stringToHotkey(hotkeyString);

      // Assert
      expect(parsedHotkey, isNotNull);
      expect(parsedHotkey?.keyCode, KeyCode.v);
      expect(parsedHotkey?.modifiers, contains(KeyModifier.cmd));
      expect(parsedHotkey?.modifiers, contains(KeyModifier.shift));
    });

    test('应该处理无效的热键字符串', () {
      // Arrange
      final invalidStrings = [
        '',
        'Invalid',
        'Cmd+', // 缺少键
        'Shift+V', // 缺少主修饰键
      ];

      // Act & Assert
      for (final string in invalidStrings) {
        final parsed = hotkeyManager.stringToHotkey(string);
        expect(parsed, isNull, reason: '无效字符串 "$string" 应该返回null');
      }
    });

    test('应该在注册前验证热键', () async {
      // Arrange
      final systemReservedHotkey = Hotkey(
        keyCode: KeyCode.q,
        modifiers: [KeyModifier.cmd],
      );

      // Act
      final canRegister = await hotkeyManager.canRegister(systemReservedHotkey);

      // Assert
      expect(canRegister, isFalse, reason: '不应该允许注册系统保留热键');
    });

    test('应该提供热键冲突的详细错误信息', () async {
      // Arrange
      final hotkey1 = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      await hotkeyManager.register(hotkey1, () {});

      final hotkey2 = Hotkey(
        keyCode: KeyCode.v,
        modifiers: [KeyModifier.cmd, KeyModifier.shift],
      );

      // Act
      final result = await hotkeyManager.registerWithDetails(hotkey2, () {});

      // Assert
      expect(result.success, isFalse);
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage, contains('conflict') ||
                                   result.errorMessage, contains('冲突'));
    });
  });
}
