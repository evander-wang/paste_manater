import 'package:flutter/material.dart';
import '../models/category_base.dart';

/// 删除分类确认对话框
///
/// 显示分类名称和项目数量,要求用户确认删除操作
class DeleteCategoryDialog extends StatelessWidget {
  const DeleteCategoryDialog({
    super.key,
    required this.category,
    required this.itemCount,
  });

  /// 要删除的分类
  final CategoryBase category;

  /// 分类下的项目数量
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('删除分类'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (itemCount > 0) ...[
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              '分类"${category.displayName}"下还有 $itemCount 个项目。',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              '请先清空或移动这些项目后再删除分类。',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ] else ...[
            Icon(
              Icons.help_outline_rounded,
              color: theme.colorScheme.primary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              '确认删除分类"${category.displayName}"吗?',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              '删除后无法恢复。',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        if (itemCount == 0)
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('删除'),
          ),
      ],
    );
  }
}
