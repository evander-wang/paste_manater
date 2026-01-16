import 'package:flutter/material.dart';
import '../services/category_manager.dart';

/// 移动到分类对话框
///
/// 显示所有可用分类（预置+自定义），让用户选择目标分类
class MoveToCategoryDialog extends StatelessWidget {
  const MoveToCategoryDialog({
    super.key,
    required this.categoryManager,
    required this.currentCategoryId,
  });

  /// 分类管理器
  final CategoryManager categoryManager;

  /// 当前分类ID（用于高亮显示）
  final String? currentCategoryId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allCategories = categoryManager.getAllCategories();

    return AlertDialog(
      title: Row(
        children: [
          const Text('移动到分类'),
          if (currentCategoryId != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '当前: ${_getCurrentCategoryName()}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 300,
        child: ListView.builder(
          itemCount: allCategories.length,
          itemBuilder: (context, index) {
            final category = allCategories[index];
            final isCurrent = category.id == currentCategoryId;

            return ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 350, // 设置最小宽度，略小于对话框宽度400
              ),
              child: ListTile(
                leading: Icon(
                  category.icon,
                  color: category.color,
                ),
                title: Text(category.displayName),
                subtitle: isCurrent
                    ? Text(
                        '当前所在分类',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(category.id),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }

  /// 获取当前分类名称
  String _getCurrentCategoryName() {
    if (currentCategoryId == null) {
      return '';
    }
    final category = categoryManager.getCategoryById(currentCategoryId!);
    return category?.displayName ?? currentCategoryId!;
  }
}
