import 'clipboard_item.dart';

/// 搜索查询模型
///
/// 表示用户的搜索输入，支持关键词匹配和可选过滤
class SearchQuery {
  /// 搜索关键词（不区分大小写）
  final String query;

  /// 可选分类过滤（分类ID）
  final String? categoryId;

  /// 可选时间范围开始
  final DateTime? startTime;

  /// 可选时间范围结束
  final DateTime? endTime;

  SearchQuery({
    required this.query,
    this.categoryId,
    this.startTime,
    this.endTime,
  });

  /// 判断单个项目是否匹配搜索查询
  bool matches(ClipboardItem item) {
    // 关键词匹配
    if (query.isNotEmpty &&
        !item.content.toLowerCase().contains(query.toLowerCase())) {
      return false;
    }

    // 分类过滤
    if (categoryId != null && item.categoryId != categoryId) {
      return false;
    }

    // 时间范围过滤
    if (startTime != null && item.timestamp.isBefore(startTime!)) {
      return false;
    }

    if (endTime != null && item.timestamp.isAfter(endTime!)) {
      return false;
    }

    return true;
  }

  /// 创建空搜索查询
  factory SearchQuery.empty() {
    return SearchQuery(query: '');
  }

  /// 检查是否为空查询
  bool get isEmpty => query.isEmpty && categoryId == null;

  /// 检查是否有过滤条件
  bool get hasFilters => categoryId != null || startTime != null || endTime != null;
}
