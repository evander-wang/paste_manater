import 'package:flutter/material.dart';
import '../models/category.dart';

/// 分类过滤器组件
class CategoryFilterWidget extends StatelessWidget {
  /// 当前选中的分类
  final Category? selectedCategory;

  /// 分类切换回调
  final ValueChanged<Category?> onCategoryToggle;

  /// 每个分类的计数
  final Map<Category, int> categoryCounts;

  /// 总记录数
  final int totalCount;

  /// 获取分类图标的回调
  final IconData Function(Category) getIcon;

  /// 获取分类颜色的回调
  final Color Function(Category) getColor;

  const CategoryFilterWidget({
    super.key,
    required this.selectedCategory,
    required this.onCategoryToggle,
    required this.categoryCounts,
    required this.totalCount,
    required this.getIcon,
    required this.getColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // "全部"按钮
          _buildCategoryButton(null, '全部', totalCount),
          // 各个分类按钮
          ...Category.values.map((category) {
            final count = categoryCounts[category] ?? 0;
            return _buildCategoryButton(
              category,
              _getCategoryLabel(category),
              count,
            );
          }),
        ],
      ),
    );
  }

  /// 构建分类按钮
  Widget _buildCategoryButton(Category? category, String label, int count) {
    final isSelected = selectedCategory == category;
    final icon = category != null ? getIcon(category) : Icons.apps;
    final color = category != null ? getColor(category) : Colors.grey;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (category != null) ...[
            Icon(icon, size: 16, color: isSelected ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Text(label),
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onCategoryToggle(category),
      selectedColor: color,
      backgroundColor: Colors.grey[100],
      checkmarkColor: Colors.white,
      elevation: isSelected ? 4 : 0,
    );
  }

  /// 获取分类的中文标签
  String _getCategoryLabel(Category category) {
    switch (category) {
      case Category.text:
        return '文本';
      case Category.link:
        return '链接';
      case Category.code:
        return '代码';
      case Category.file:
        return '文件';
    }
  }
}
