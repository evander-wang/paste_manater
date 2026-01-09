import 'clipboard_item.dart';
import 'category.dart';

/// 剪贴板历史集合模型
///
/// 表示所有剪贴板项目的有序集合，强制执行最大数量/大小限制和 FIFO 移除策略
class ClipboardHistory {
  /// 项目列表（按时间倒序，最新的在前）
  final List<ClipboardItem> items;

  /// 最大项目数量
  final int maxItems;

  /// 最大总大小（字节）
  final int maxSize;

  ClipboardHistory({
    List<ClipboardItem>? initialItems,
    this.maxItems = 1000,
    this.maxSize = 100 * 1024 * 1024, // 100MB
  }) : items = initialItems ?? [];

  /// 获取当前项目总数
  int get totalCount => items.length;

  /// 获取当前总大小（字节）
  int get totalSize => items.fold(0, (sum, item) => sum + item.size);

  /// 添加项目到历史
  ///
  /// 自动去重和限制强制执行：
  /// - 如果是重复项（5秒内相同内容），则不添加
  /// - 如果超过限制，移除最旧的项目
  ClipboardHistory add(ClipboardItem newItem) {
    // 去重检查
    if (_containsDuplicate(newItem)) {
      return this;
    }

    final newItems = [...items, newItem];

    // 强制限制（移除最旧项目）
    final enforcedItems = _enforceLimits(newItems);

    return ClipboardHistory(
      initialItems: enforcedItems,
      maxItems: maxItems,
      maxSize: maxSize,
    );
  }

  /// 移除指定项目
  ClipboardHistory remove(String id) {
    final newItems = items.where((item) => item.id != id).toList();
    return ClipboardHistory(
      initialItems: newItems,
      maxItems: maxItems,
      maxSize: maxSize,
    );
  }

  /// 清空所有历史
  ClipboardHistory clear() {
    return ClipboardHistory(
      maxItems: maxItems,
      maxSize: maxSize,
    );
  }

  /// 按分类过滤
  List<ClipboardItem> filterBy(Category category) {
    return items.where((item) => item.category == category).toList();
  }

  /// 搜索项目
  List<ClipboardItem> search(String query) {
    if (query.isEmpty) {
      return items;
    }

    final lowerQuery = query.toLowerCase();
    return items.where((item) {
      return item.content.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// 检查是否包含重复项
  bool _containsDuplicate(ClipboardItem newItem) {
    return items.any((item) => item.isDuplicate(newItem));
  }

  /// 强制执行限制（移除最旧项目）
  List<ClipboardItem> _enforceLimits(List<ClipboardItem> itemList) {
    var enforced = itemList.toList();

    // 按时间倒序排列（最新的在前）
    enforced.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // 移除最旧项目直到满足限制
    while (enforced.length > maxItems || _calculateTotalSize(enforced) > maxSize) {
      if (enforced.isEmpty) break;
      enforced.removeLast();
    }

    return enforced;
  }

  /// 计算列表总大小
  int _calculateTotalSize(List<ClipboardItem> itemList) {
    return itemList.fold(0, (sum, item) => sum + item.size);
  }

  /// 获取最旧的项目
  ClipboardItem? get oldest {
    if (items.isEmpty) return null;
    return items.reduce((a, b) => a.timestamp.isBefore(b.timestamp) ? a : b);
  }

  /// 从 JSON 创建 ClipboardHistory
  factory ClipboardHistory.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>?;
    final items = itemsList
            ?.map((itemJson) => ClipboardItem.fromJson(itemJson as Map<String, dynamic>))
            .toList() ??
        [];

    return ClipboardHistory(
      initialItems: items,
      maxItems: json['maxItems'] as int? ?? 1000,
      maxSize: json['maxSize'] as int? ?? 100 * 1024 * 1024,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'version': 1,
      'items': items.map((item) => item.toJson()).toList(),
      'maxItems': maxItems,
      'maxSize': maxSize,
      'metadata': {
        'totalCount': totalCount,
        'totalSize': totalSize,
        if (items.isNotEmpty)
          'oldestTimestamp': oldest!.timestamp.toIso8601String(),
        if (items.isNotEmpty)
          'newestTimestamp': items.first.timestamp.toIso8601String(),
      },
    };
  }
}
