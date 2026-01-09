import '../models/clipboard_item.dart';
import '../models/category.dart' as models;

/// 分类器服务
///
/// 提供基于内容的自动分类功能
class Categorizer {
  /// 分类剪贴板项目
  ///
  /// 根据项目内容和类型自动分类
  static models.Category classifyItem(ClipboardItem item) {
    return models.CategoryClassifier.classify(
      item.content,
      _mapItemTypeToDataType(item.type),
    );
  }

  /// 批量分类项目
  static List<ClipboardItem> classifyItems(List<ClipboardItem> items) {
    return items.map((item) {
      final category = classifyItem(item);
      // 返回新项目（如果分类不同）
      if (item.category != category) {
        return ClipboardItem(
          id: item.id,
          content: item.content,
          type: item.type,
          category: category,
          timestamp: item.timestamp,
          hash: item.hash,
          size: item.size,
          sourceApp: item.sourceApp,
        );
      }
      return item;
    }).toList();
  }

  /// 映射 ClipboardItemType 到 ClipboardDataType
  static models.ClipboardDataType _mapItemTypeToDataType(
      ClipboardItemType type) {
    switch (type) {
      case ClipboardItemType.text:
      case ClipboardItemType.url:
      case ClipboardItemType.file:
        return models.ClipboardDataType.text;
    }
  }

  /// 获取分类统计信息
  static Map<models.Category, int> getCategoryStats(
      List<ClipboardItem> items) {
    final stats = <models.Category, int>{};

    for (final item in items) {
      stats[item.category] = (stats[item.category] ?? 0) + 1;
    }

    return stats;
  }

  /// 验证分类准确率
  ///
  /// 用于测试分类器的准确性
  static double calculateAccuracy(
    List<ClipboardItem> items,
    Map<String, models.Category> expectedCategories,
  ) {
    if (items.isEmpty) {
      return 1.0;
    }

    int correct = 0;

    for (final item in items) {
      final expected = expectedCategories[item.content];
      if (expected != null && item.category == expected) {
        correct++;
      }
    }

    return correct / items.length;
  }
}
