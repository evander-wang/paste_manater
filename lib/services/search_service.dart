import '../models/clipboard_history.dart';
import '../models/clipboard_item.dart';
import '../models/search_query.dart';

/// 搜索服务
///
/// 提供内存哈希索引以实现 O(1) 查找
class SearchService {
  /// 分类索引（O(1) 分类过滤）
  final Map<String, List<String>> _categoryIndex = {};

  /// 哈希索引（O(1) 查找）
  final Map<String, ClipboardItem> _hashIndex = {};

  /// 构建索引
  void buildIndex(ClipboardHistory history) {
    _categoryIndex.clear();
    _hashIndex.clear();

    for (final item in history.items) {
      // 构建分类索引
      _categoryIndex.putIfAbsent(item.categoryId, () => []);
      _categoryIndex[item.categoryId]!.add(item.id);

      // 构建哈希索引
      _hashIndex[item.hash] = item;
    }
  }

  /// 搜索项目
  ///
  /// O(1) 分类过滤 + O(n) 文本搜索
  List<ClipboardItem> search(ClipboardHistory history, SearchQuery query) {
    var results = history.items.toList();

    // 如果有分类过滤，使用索引快速过滤
    if (query.categoryId != null) {
      final itemIds = _categoryIndex[query.categoryId] ?? [];
      results = results.where((item) => itemIds.contains(item.id)).toList();
    }

    // 关键词匹配（不区分大小写）
    if (query.query.isNotEmpty) {
      final lowerQuery = query.query.toLowerCase();
      results = results.where((item) {
        return item.content.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    // 时间范围过滤
    if (query.startTime != null) {
      results = results.where((item) => !item.timestamp.isBefore(query.startTime!)).toList();
    }

    if (query.endTime != null) {
      results = results.where((item) => !item.timestamp.isAfter(query.endTime!)).toList();
    }

    return results;
  }

  /// 通过哈希快速查找项目
  ClipboardItem? findByHash(String hash) {
    return _hashIndex[hash];
  }

  /// 获取分类统计
  Map<String, int> getCategoryStats() {
    final stats = <String, int>{};

    for (final entry in _categoryIndex.entries) {
      stats[entry.key] = entry.value.length;
    }

    return stats;
  }

  /// 清空索引
  void clear() {
    _categoryIndex.clear();
    _hashIndex.clear();
  }
}
