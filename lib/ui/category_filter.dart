import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/clipboard_history.dart';

/// 分类过滤器组件
///
/// 提供分类标签按钮和计数徽章
class CategoryFilter extends StatefulWidget {
  /// 当前选中的分类
  final Category? selectedCategory;

  /// 分类选择回调
  final ValueChanged<Category?>? onCategorySelected;

  /// 剪贴板历史（用于计算计数）
  final ClipboardHistory? history;

  /// 是否显示计数徽章
  final bool showCountBadges;

  /// 自定义分类标签文本
  final Map<Category, String>? customLabels;

  const CategoryFilter({
    super.key,
    this.selectedCategory,
    this.onCategorySelected,
    this.history,
    this.showCountBadges = true,
    this.customLabels,
  });

  @override
  State<CategoryFilter> createState() => _CategoryFilterState();
}

class _CategoryFilterState extends State<CategoryFilter> {
  /// 获取分类的显示名称
  String _getCategoryLabel(Category category) {
    if (widget.customLabels != null) {
      return widget.customLabels![category] ?? _getDefaultLabel(category);
    }
    return _getDefaultLabel(category);
  }

  /// 获取默认标签
  String _getDefaultLabel(Category category) {
    switch (category) {
      case Category.text:
        return '文本';
      case Category.image:
        return '图像';
      case Category.link:
        return '链接';
      case Category.code:
        return '代码';
      case Category.file:
        return '文件';
    }
  }

  /// 获取分类的项目计数
  int _getCategoryCount(Category? category) {
    if (widget.history == null) return 0;

    if (category == null) {
      // "全部"分类
      return widget.history!.totalCount;
    }

    final items = widget.history!.filterBy(category);
    return items.length;
  }

  /// 获取分类图标
  IconData _getCategoryIcon(Category category) {
    switch (category) {
      case Category.text:
        return Icons.text_snippet;
      case Category.image:
        return Icons.image;
      case Category.link:
        return Icons.link;
      case Category.code:
        return Icons.code;
      case Category.file:
        return Icons.insert_drive_file;
    }
  }

  /// 获取分类颜色
  Color _getCategoryColor(Category category) {
    switch (category) {
      case Category.text:
        return Colors.blueGrey;
      case Category.image:
        return Colors.purple;
      case Category.link:
        return Colors.blue;
      case Category.code:
        return Colors.green;
      case Category.file:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildCategoryChip(null, '全部'),
            const SizedBox(width: 8),
            ...Category.values.map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildCategoryChip(category, _getCategoryLabel(category)),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 构建分类过滤器按钮
  Widget _buildCategoryChip(Category? category, String label) {
    final isSelected = widget.selectedCategory == category;
    final count = _getCategoryCount(category);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (category != null) ...[
            Icon(
              _getCategoryIcon(category),
              size: 16,
              color: isSelected
                  ? _getCategoryColor(category)
                  : Colors.grey[600],
            ),
            const SizedBox(width: 4),
          ],
          Text(label),
          if (widget.showCountBadges) ...[
            const SizedBox(width: 4),
            _buildCountBadge(count),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        widget.onCategorySelected?.call(selected ? category : null);
      },
      selectedColor: _isSelectedColor(category),
      checkmarkColor: _getCategoryColor(category ?? Category.text),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? _getCategoryColor(category ?? Category.text)
            : Colors.grey[700],
      ),
      backgroundColor: Colors.grey[100],
      side: BorderSide(
        color: isSelected
            ? _getCategoryColor(category ?? Category.text)
            : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
      elevation: isSelected ? 2 : 0,
      shadowColor: _getCategoryColor(category ?? Category.text).withOpacity(0.3),
    );
  }

  /// 构建计数徽章
  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: count > 0 ? Colors.blue[700] : Colors.grey[400],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  /// 获取选中状态的颜色
  Color? _isSelectedColor(Category? category) {
    if (category == null) {
      return Colors.blue[100];
    }
    switch (category) {
      case Category.text:
        return Colors.blueGrey[100];
      case Category.image:
        return Colors.purple[100];
      case Category.link:
        return Colors.blue[100];
      case Category.code:
        return Colors.green[100];
      case Category.file:
        return Colors.orange[100];
    }
  }
}

/// 分类过滤器按钮（简化版本）
class CategoryFilterButton extends StatelessWidget {
  final Category category;
  final String label;
  final bool isSelected;
  final int count;
  final VoidCallback? onTap;
  final bool showCount;

  const CategoryFilterButton({
    super.key,
    required this.category,
    required this.label,
    required this.isSelected,
    this.count = 0,
    this.onTap,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (showCount) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey[600],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.blue[700] : Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap?.call(),
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? Colors.blue[700] : Colors.grey[700],
      ),
    );
  }
}
