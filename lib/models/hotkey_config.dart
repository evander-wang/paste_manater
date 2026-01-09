/// 热键配置数据模型
///
/// 定义热键的按键码和修饰键组合
class HotkeyConfig {
  /// 主键（例如 'V' 对应 VK_V）
  final String keyCode;

  /// 修饰键列表（可选值：Cmd, Shift, Option, Control）
  final List<String> modifiers;

  const HotkeyConfig({
    required this.keyCode,
    required this.modifiers,
  });

  /// 默认热键配置（Cmd+Shift+V）
  static const HotkeyConfig defaultHotkey = HotkeyConfig(
    keyCode: 'V',
    modifiers: ['Cmd', 'Shift'],
  );

  /// 从 JSON 创建
  factory HotkeyConfig.fromJson(Map<String, dynamic> json) {
    return HotkeyConfig(
      keyCode: json['keyCode'] as String,
      modifiers: List<String>.from(json['modifiers'] as List),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'keyCode': keyCode,
      'modifiers': modifiers,
    };
  }

  /// 获取显示名称
  String get displayName {
    final modifierSymbols = modifiers.map((m) {
      switch (m) {
        case 'Cmd':
        case 'Command':
          return '⌘';
        case 'Shift':
          return '⇧';
        case 'Option':
        case 'Alt':
          return '⌥';
        case 'Control':
        case 'Ctrl':
          return '⌃';
        default:
          return m;
      }
    }).join('');

    return '$modifierSymbols$keyCode';
  }

  /// 复制并修改
  HotkeyConfig copyWith({
    String? keyCode,
    List<String>? modifiers,
  }) {
    return HotkeyConfig(
      keyCode: keyCode ?? this.keyCode,
      modifiers: modifiers ?? this.modifiers,
    );
  }

  @override
  String toString() => displayName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HotkeyConfig &&
        other.keyCode == keyCode &&
        _listEquals(other.modifiers, modifiers);
  }

  @override
  int get hashCode => keyCode.hashCode ^ modifiers.hashCode;

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
