import 'package:flutter/material.dart';
import '../models/category.dart';

/// 分类过滤器组件
///
/// 现代化的分段控制器设计，支持平滑动画和优雅的视觉效果
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
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // "全部"按钮
          Expanded(
            child: _buildFilterButton(
              context,
              category: null,
              label: '全部',
              count: totalCount,
              icon: Icons.apps_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          // 各个分类按钮
          ...Category.values.map((category) {
            final count = categoryCounts[category] ?? 0;
            return Expanded(
              child: _buildFilterButton(
                context,
                category: category,
                label: _getCategoryLabel(category),
                count: count,
                icon: getIcon(category),
                color: getColor(category),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 构建过滤器按钮
  Widget _buildFilterButton(
    BuildContext context, {
    required Category? category,
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = selectedCategory == category;
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Material(
        color: isSelected
            ? color
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => onCategoryToggle(category),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : color.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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
