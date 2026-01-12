/// 置顶状态基类
///
/// 为Command和ClipboardItem提供置顶能力
///
/// 使用方式:
/// ```dart
/// class Command extends PinStatus {
///   @override
///   bool pinned;
///
///   @override
///   DateTime? pinnedAt;
///
///   // ... 其他字段和方法
/// }
/// ```
abstract class PinStatus {
  /// 是否置顶
  bool get pinned;

  /// 置顶时间戳
  DateTime? get pinnedAt;

  /// 置顶此项目
  ///
  /// 设置[pinned]为true,[pinnedAt]为当前时间
  /// 子类需要实现此方法来修改内部状态
  void pin() {
    // 由子类实现
  }

  /// 取消置顶
  ///
  /// 设置[pinned]为false,[pinnedAt]为null
  /// 子类需要实现此方法来修改内部状态
  void unpin() {
    // 由子类实现
  }

  /// 是否已置顶
  bool get isPinned => pinned == true;
}
