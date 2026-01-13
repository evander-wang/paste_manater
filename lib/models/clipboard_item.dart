import 'category.dart';
import 'pin_status.dart';

/// 剪贴板项目数据模型
///
/// 表示单个捕获的剪贴板条目，包含内容、元数据和分类信息
class ClipboardItem extends PinStatus {
  /// 唯一标识符（UUID v4 格式）
  final String id;

  /// 剪贴板内容（文本或 JSON 编码的二进制）
  final String content;

  /// 数据类型
  final ClipboardItemType type;

  /// 自动分类结果
  final Category category;

  /// 捕获时间戳（ISO 8601 格式）
  final DateTime timestamp;

  /// 内容哈希（SHA-256 前 8 字符，用于去重）
  final String hash;

  /// 内容大小（字节）
  final int size;

  /// 源应用 Bundle ID（可选，由于 macOS 隐私限制）
  final String? sourceApp;

  /// 是否置顶
  @override
  final bool pinned;

  /// 置顶时间戳
  @override
  final DateTime? pinnedAt;

  ClipboardItem({
    required this.id,
    required this.content,
    required this.type,
    required this.category,
    required this.timestamp,
    required this.hash,
    required this.size,
    this.sourceApp,
    this.pinned = false,
    this.pinnedAt,
  });

  /// 从 JSON 创建 ClipboardItem
  factory ClipboardItem.fromJson(Map<String, dynamic> json) {
    return ClipboardItem(
      id: json['id'] as String,
      content: json['content'] as String,
      type: ClipboardItemType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ClipboardItemType.text,
      ),
      category: Category.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => Category.text,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      hash: json['hash'] as String,
      size: json['size'] as int,
      sourceApp: json['sourceApp'] as String?,
      // 向后兼容:旧文件缺少pinned字段时,默认为false
      pinned: json['pinned'] as bool? ?? false,
      pinnedAt: json['pinnedAt'] != null
          ? DateTime.parse(json['pinnedAt'] as String)
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.name,
      'category': category.name,
      'timestamp': timestamp.toIso8601String(),
      'hash': hash,
      'size': size,
      if (sourceApp != null) 'sourceApp': sourceApp,
      'pinned': pinned,
      'pinnedAt': pinnedAt?.toIso8601String(),
    };
  }

  /// 创建新ClipboardItem并修改指定字段
  ClipboardItem copyWith({
    String? id,
    String? content,
    ClipboardItemType? type,
    Category? category,
    DateTime? timestamp,
    String? hash,
    int? size,
    String? sourceApp,
    bool? pinned,
    DateTime? pinnedAt,
    bool clearPinnedAt = false,
  }) {
    return ClipboardItem(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      hash: hash ?? this.hash,
      size: size ?? this.size,
      sourceApp: sourceApp ?? this.sourceApp,
      pinned: pinned ?? this.pinned,
      // 如果 clearPinnedAt 为 true,则清除 pinnedAt
      // 否则如果提供了新的 pinnedAt,使用新值
      // 否则保留原值
      pinnedAt: clearPinnedAt ? null : (pinnedAt ?? this.pinnedAt),
    );
  }

  @override
  bool get isPinned => pinned == true;

  /// 检查是否与另一个项目重复（相同哈希 + 时间窗口 5 秒内）
  bool isDuplicate(ClipboardItem other) {
    return hash == other.hash &&
        timestamp.difference(other.timestamp).abs() < const Duration(seconds: 5);
  }
}

/// 剪贴板数据类型枚举
enum ClipboardItemType {
  text,
  url,
  file,
  image,
}
