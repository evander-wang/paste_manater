import 'dart:async';
import 'package:flutter/services.dart';
import '../models/clipboard_history.dart';
import 'storage_service.dart';

/// 热键组合
class Hotkey {
  /// 按键码
  final KeyCode keyCode;

  /// 修饰键列表
  final List<KeyModifier> modifiers;

  const Hotkey({
    required this.keyCode,
    required this.modifiers,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Hotkey &&
      other.keyCode == keyCode &&
      _listsEqual(other.modifiers, modifiers);
  }

  @override
  int get hashCode => keyCode.hashCode ^ modifiers.hashCode;

  bool _listsEqual<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// 按键码枚举
enum KeyCode {
  a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z,
  unknown,
}

/// 修饰键枚举
enum KeyModifier {
  cmd,
  shift,
  option,
  control,
  capsLock,
}

/// 热键注册结果
class HotkeyRegistrationResult {
  final bool success;
  final String? errorMessage;

  const HotkeyRegistrationResult({
    required this.success,
    this.errorMessage,
  });
}

/// 热键管理器
///
/// 提供全局热键注册、冲突检测和用户自定义功能
class HotkeyManager {
  /// 存储服务（用于保存用户热键配置）
  final StorageService? storageService;

  /// Method Channel 用于 macOS 原生热键访问
  static const _platform = MethodChannel('paste_manager/hotkey');

  /// 当前注册的热键
  Hotkey? _currentHotkey;

  /// 热键回调函数
  void Function(Hotkey)? _hotkeyCallback;

  /// 是否已注册
  bool _isRegistered = false;

  /// 是否暂停监听
  bool _isPaused = false;

  /// 默认热键：Cmd+Shift+V
  static const Hotkey defaultHotkey = Hotkey(
    keyCode: KeyCode.v,
    modifiers: [KeyModifier.cmd, KeyModifier.shift],
  );

  /// 系统保留热键列表
  static const List<Hotkey> systemReservedHotkeys = [
    Hotkey(keyCode: KeyCode.q, modifiers: [KeyModifier.cmd]), // Cmd+Q: 退出
    Hotkey(keyCode: KeyCode.w, modifiers: [KeyModifier.cmd]), // Cmd+W: 关闭窗口
    Hotkey(keyCode: KeyCode.c, modifiers: [KeyModifier.cmd]), // Cmd+C: 复制
    Hotkey(keyCode: KeyCode.v, modifiers: [KeyModifier.cmd]), // Cmd+V: 粘贴
    Hotkey(keyCode: KeyCode.x, modifiers: [KeyModifier.cmd]), // Cmd+X: 剪切
    Hotkey(keyCode: KeyCode.a, modifiers: [KeyModifier.cmd]), // Cmd+A: 全选
    Hotkey(keyCode: KeyCode.z, modifiers: [KeyModifier.cmd]), // Cmd+Z: 撤销
    Hotkey(keyCode: KeyCode.s, modifiers: [KeyModifier.cmd]), // Cmd+S: 保存
    Hotkey(keyCode: KeyCode.p, modifiers: [KeyModifier.cmd]), // Cmd+P: 打印
    Hotkey(keyCode: KeyCode.n, modifiers: [KeyModifier.cmd]), // Cmd+N: 新建
  ];

  HotkeyManager({this.storageService});

  /// 注册热键
  Future<bool> register(Hotkey hotkey, void Function() callback) async {
    return registerWithDetails(hotkey, (hotkey) => callback()).then((result) => result.success);
  }

  /// 注册热键（带详细信息的版本）
  Future<HotkeyRegistrationResult> registerWithDetails(
    Hotkey hotkey,
    void Function(Hotkey) callback,
  ) async {
    // 验证热键
    if (!isValidHotkey(hotkey)) {
      return const HotkeyRegistrationResult(
        success: false,
        errorMessage: '无效的热键组合',
      );
    }

    // 检查是否与系统保留热键冲突
    if (isSystemReserved(hotkey)) {
      return const HotkeyRegistrationResult(
        success: false,
        errorMessage: '该热键被系统保留',
      );
    }

    // 如果已经注册，先注销
    if (_isRegistered) {
      await unregister();
    }

    try {
      // 调用原生代码注册热键
      final success = await _platform.invokeMethod('registerHotkey', {
        'keyCode': _keyCodeToString(hotkey.keyCode),
        'modifiers': hotkey.modifiers.map(_modifierToString).toList(),
      });

      if (success == true) {
        _currentHotkey = hotkey;
        _hotkeyCallback = callback;
        _isRegistered = true;

        // 设置原生热键触发回调
        _platform.setMethodCallHandler(_handleHotkeyEvent);

        return const HotkeyRegistrationResult(success: true);
      } else {
        return const HotkeyRegistrationResult(
          success: false,
          errorMessage: '原生热键注册失败',
        );
      }
    } catch (e) {
      return HotkeyRegistrationResult(
        success: false,
        errorMessage: '热键注册失败: $e',
      );
    }
  }

  /// 注销热键
  Future<void> unregister() async {
    if (!_isRegistered) return;

    try {
      await _platform.invokeMethod('unregisterHotkey');
      _currentHotkey = null;
      _hotkeyCallback = null;
      _isRegistered = false;
      _platform.setMethodCallHandler(null);
    } catch (e) {
      // 忽略注销错误
    }
  }

  /// 切换窗口显示/隐藏
  /// 返回 true 表示窗口现在显示，false 表示窗口现在隐藏
  Future<bool> toggleWindow() async {
    try {
      print('📱 [Dart] 调用原生 toggleWindow 方法');
      final result = await _platform.invokeMethod('toggleWindow');
      final isVisible = result == true;
      print('📱 [Dart] toggleWindow 返回: $result (窗口${isVisible ? "显示" : "隐藏"})');
      return isVisible;
    } catch (e) {
      print('❌ [Dart] toggleWindow 失败: $e');
      throw Exception('窗口切换失败: $e');
    }
  }

  /// 处理原生热键事件
  Future<void> _handleHotkeyEvent(MethodCall call) async {
    if (call.method == 'hotkeyPressed' && !_isPaused) {
      _hotkeyCallback?.call(_currentHotkey!);
    }
  }

  /// 暂停热键监听
  Future<void> pause() async {
    _isPaused = true;
  }

  /// 恢复热键监听
  Future<void> resume() async {
    _isPaused = false;
  }

  /// 检查两个热键是否冲突
  bool hasConflict(Hotkey hotkey1, Hotkey hotkey2) {
    return hotkey1 == hotkey2;
  }

  /// 检查热键是否被系统保留
  bool isSystemReserved(Hotkey hotkey) {
    return systemReservedHotkeys.any((reserved) => reserved == hotkey);
  }

  /// 验证热键是否有效
  bool isValidHotkey(Hotkey hotkey) {
    // 必须有修饰键
    if (hotkey.modifiers.isEmpty) {
      return false;
    }

    // 必须有有效的按键码
    if (hotkey.keyCode == KeyCode.unknown) {
      return false;
    }

    // 必须至少包含一个主修饰键（Cmd、Option、Control）
    final hasMainModifier = hotkey.modifiers.any((modifier) =>
      modifier == KeyModifier.cmd ||
      modifier == KeyModifier.option ||
      modifier == KeyModifier.control
    );

    return hasMainModifier;
  }

  /// 检查是否可以注册热键
  Future<bool> canRegister(Hotkey hotkey) async {
    return isValidHotkey(hotkey) && !isSystemReserved(hotkey);
  }

  /// 重置为默认热键
  Future<bool> resetToDefault() async {
    return await register(defaultHotkey, () {});
  }

  /// 获取当前热键
  Hotkey? get currentHotkey => _currentHotkey;

  /// 是否已注册
  bool get isRegistered => _isRegistered;

  /// 获取已注册热键数量
  int get registeredCount => _isRegistered ? 1 : 0;

  /// 获取热键回调（用于测试）
  void Function(Hotkey)? getCallback() => _hotkeyCallback;

  /// 保存热键配置到存储
  Future<void> saveHotkeyPreference() async {
    if (storageService == null || _currentHotkey == null) return;

    final history = await storageService!.load();
    // TODO: 将热键配置保存到历史元数据中
    await storageService!.save(history);
  }

  /// 从存储加载热键配置
  Future<void> loadHotkeyPreference() async {
    if (storageService == null) return;

    final history = await storageService!.load();
    // TODO: 从历史元数据中加载热键配置
  }

  /// 获取系统保留热键列表
  List<Hotkey> getSystemReservedHotkeys() {
    return List.unmodifiable(systemReservedHotkeys);
  }

  /// 将热键转换为字符串表示
  String hotkeyToString(Hotkey hotkey) {
    final modifierStrings = hotkey.modifiers.map(_modifierToString).toList();
    final keyString = _keyCodeToString(hotkey.keyCode);
    return '${modifierStrings.join('+')}+$keyString';
  }

  /// 从字符串解析热键
  Hotkey? stringToHotkey(String hotkeyString) {
    final parts = hotkeyString.split('+');
    if (parts.length < 2) return null;

    final modifiers = <KeyModifier>[];
    KeyCode? keyCode;

    for (final part in parts) {
      final modifier = _stringToModifier(part.trim());
      if (modifier != null) {
        modifiers.add(modifier);
      } else {
        final key = _stringToKeyCode(part.trim());
        if (key != null && key != KeyCode.unknown) {
          keyCode = key;
        }
      }
    }

    if (keyCode == null || modifiers.isEmpty) {
      return null;
    }

    return Hotkey(
      keyCode: keyCode,
      modifiers: modifiers,
    );
  }

  // 私有辅助方法

  String _keyCodeToString(KeyCode keyCode) {
    switch (keyCode) {
      case KeyCode.a: return 'A';
      case KeyCode.b: return 'B';
      case KeyCode.c: return 'C';
      case KeyCode.d: return 'D';
      case KeyCode.e: return 'E';
      case KeyCode.f: return 'F';
      case KeyCode.g: return 'G';
      case KeyCode.h: return 'H';
      case KeyCode.i: return 'I';
      case KeyCode.j: return 'J';
      case KeyCode.k: return 'K';
      case KeyCode.l: return 'L';
      case KeyCode.m: return 'M';
      case KeyCode.n: return 'N';
      case KeyCode.o: return 'O';
      case KeyCode.p: return 'P';
      case KeyCode.q: return 'Q';
      case KeyCode.r: return 'R';
      case KeyCode.s: return 'S';
      case KeyCode.t: return 'T';
      case KeyCode.u: return 'U';
      case KeyCode.v: return 'V';
      case KeyCode.w: return 'W';
      case KeyCode.x: return 'X';
      case KeyCode.y: return 'Y';
      case KeyCode.z: return 'Z';
      case KeyCode.unknown: return '?';
    }
  }

  KeyCode _stringToKeyCode(String string) {
    switch (string.toUpperCase()) {
      case 'A': return KeyCode.a;
      case 'B': return KeyCode.b;
      case 'C': return KeyCode.c;
      case 'D': return KeyCode.d;
      case 'E': return KeyCode.e;
      case 'F': return KeyCode.f;
      case 'G': return KeyCode.g;
      case 'H': return KeyCode.h;
      case 'I': return KeyCode.i;
      case 'J': return KeyCode.j;
      case 'K': return KeyCode.k;
      case 'L': return KeyCode.l;
      case 'M': return KeyCode.m;
      case 'N': return KeyCode.n;
      case 'O': return KeyCode.o;
      case 'P': return KeyCode.p;
      case 'Q': return KeyCode.q;
      case 'R': return KeyCode.r;
      case 'S': return KeyCode.s;
      case 'T': return KeyCode.t;
      case 'U': return KeyCode.u;
      case 'V': return KeyCode.v;
      case 'W': return KeyCode.w;
      case 'X': return KeyCode.x;
      case 'Y': return KeyCode.y;
      case 'Z': return KeyCode.z;
      default: return KeyCode.unknown;
    }
  }

  String _modifierToString(KeyModifier modifier) {
    switch (modifier) {
      case KeyModifier.cmd: return 'Cmd';
      case KeyModifier.shift: return 'Shift';
      case KeyModifier.option: return 'Option';
      case KeyModifier.control: return 'Control';
      case KeyModifier.capsLock: return 'CapsLock';
    }
  }

  KeyModifier? _stringToModifier(String string) {
    switch (string) {
      case 'Cmd':
      case 'Command':
      case '⌘':
        return KeyModifier.cmd;
      case 'Shift':
      case '⇧':
        return KeyModifier.shift;
      case 'Option':
      case 'Alt':
      case '⌥':
        return KeyModifier.option;
      case 'Control':
      case 'Ctrl':
      case '⌃':
        return KeyModifier.control;
      case 'CapsLock':
        return KeyModifier.capsLock;
      default:
        return null;
    }
  }
}
