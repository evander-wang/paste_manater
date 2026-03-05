import 'package:flutter/material.dart';
import '../services/category_manager.dart';

/// 分类显示辅助工具类
/// 统一处理分类图标和颜色的获取
class CategoryDisplayHelper {
  /// 获取分类图标
  ///
  /// 参数:
  /// - [categoryId] 分类ID（可为null）
  /// - [manager] 分类管理器实例
  ///
  /// 返回: 分类图标，如果分类不存在则返回默认图标
  static IconData getIcon(String? categoryId, CategoryManager manager) {
    if (categoryId == null) {
      return Icons.text_snippet;
    }
    final category = manager.getCategoryById(categoryId);
    return category?.icon ?? Icons.text_snippet;
  }

  /// 获取分类颜色
  ///
  /// 参数:
  /// - [categoryId] 分类ID（可为null）
  /// - [manager] 分类管理器实例
  ///
  /// 返回: 分类颜色，如果分类不存在则返回默认颜色
  static Color getColor(String? categoryId, CategoryManager manager) {
    if (categoryId == null) {
      return Colors.blueGrey;
    }
    final category = manager.getCategoryById(categoryId);
    return category?.color ?? Colors.blueGrey;
  }
}
