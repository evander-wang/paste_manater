import 'pin_status.dart';

/// 常用命令模型
///
/// 代表用户保存的常用命令,用于快速复制到剪贴板
///
/// JSON示例:
/// ```json
/// {
///   "id": "550e8400-e29b-41d4-a716-446655440000",
///   "name": "启动开发服务器",
///   "command": "npm run dev",
///   "createdAt": "2026-01-12T10:00:00.000Z",
///   "modifiedAt": "2026-01-12T10:00:00.000Z",
///   "pinned": false,
///   "pinnedAt": null
/// }
/// ```
class Command extends PinStatus {
  /// 唯一标识符(UUID格式)
  final String id;

  /// 命令名称(显示用)
  /// 验证规则: 非空,1-100字符
  final String name;

  /// 实际命令内容(复制用)
  /// 验证规则: 非空,1-10000字符
  final String command;

  /// 创建时间
  final DateTime createdAt;

  /// 最后修改时间
  final DateTime modifiedAt;

  /// 是否置顶
  @override
  final bool pinned;

  /// 置顶时间戳
  @override
  final DateTime? pinnedAt;

  Command({
    required this.id,
    required this.name,
    required this.command,
    required this.createdAt,
    required this.modifiedAt,
    this.pinned = false,
    this.pinnedAt,
  });

  /// 从JSON创建Command实例
  factory Command.fromJson(Map<String, dynamic> json) {
    return Command(
      id: json['id'] as String,
      name: json['name'] as String,
      command: json['command'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      // 向后兼容:旧文件缺少pinned字段时,默认为false
      pinned: json['pinned'] as bool? ?? false,
      pinnedAt: json['pinnedAt'] != null
          ? DateTime.parse(json['pinnedAt'] as String)
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'command': command,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'pinned': pinned,
      'pinnedAt': pinnedAt?.toIso8601String(),
    };
  }

  /// 创建新Command并修改指定字段
  Command copyWith({
    String? id,
    String? name,
    String? command,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? pinned,
    DateTime? pinnedAt,
    bool clearPinnedAt = false,
  }) {
    return Command(
      id: id ?? this.id,
      name: name ?? this.name,
      command: command ?? this.command,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      pinned: pinned ?? this.pinned,
      // 如果 clearPinnedAt 为 true,则清除 pinnedAt
      // 否则如果提供了新的 pinnedAt,使用新值
      // 否则保留原值
      pinnedAt: clearPinnedAt ? null : (pinnedAt ?? this.pinnedAt),
    );
  }

  /// 验证字段规则
  ///
  /// 抛出[ArgumentOutOfRangeException]如果验证失败
  void validate() {
    // 验证name: 1-100字符
    if (name.isEmpty || name.length > 100) {
      throw ArgumentError(
        'name必须在1-100字符之间(当前:${name.length})',
      );
    }

    // 验证command: 1-10000字符
    if (command.isEmpty || command.length > 10000) {
      throw ArgumentError(
        'command必须在1-10000字符之间(当前:${command.length})',
      );
    }

    // 验证:如果pinned=true,则pinnedAt不能为null
    if (pinned == true && pinnedAt == null) {
      throw ArgumentError(
        'pinned=true时pinnedAt不能为null',
      );
    }
  }

  /// 置顶此命令
  ///
  /// 返回新的Command实例,pinned=true,pinnedAt=当前时间
  @override
  void pin() {
    // 由copyWith实现,外部使用
  }

  /// 取消置顶
  ///
  /// 返回新的Command实例,pinned=false,pinnedAt=null
  @override
  void unpin() {
    // 由copyWith实现,外部使用
  }

  @override
  bool get isPinned => pinned == true;

  @override
  String toString() {
    return 'Command(id: $id, name: $name, command: $command, pinned: $pinned)';
  }
}

/// 验证异常
class CommandValidationException implements Exception {
  final String message;

  CommandValidationException(this.message);

  @override
  String toString() => 'CommandValidationException: $message';
}
