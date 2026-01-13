import 'package:flutter/material.dart';
import '../models/clipboard_item.dart';
import '../models/category.dart';

/// 剪贴板列表项组件
///
/// 显示单个剪贴板历史项,包括图标、内容和操作按钮
class ClipboardListItemWidget extends StatelessWidget {
  /// 剪贴板项目数据
  final ClipboardItem item;

  /// 是否选中
  final bool isSelected;

  /// 点击回调
  final VoidCallback onTap;

  /// 长按回调
  final VoidCallback onLongPress;

  /// 复制回调
  final VoidCallback onCopy;

  /// 删除回调
  final VoidCallback onDelete;

  /// 获取分类图标的回调
  final IconData Function(Category) getIcon;

  /// 获取分类颜色的回调
  final Color Function(Category) getColor;

  const ClipboardListItemWidget({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onCopy,
    required this.onDelete,
    required this.getIcon,
    required this.getColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        elevation: isSelected ? 8 : (item.pinned ? 4 : 2),
        shadowColor: theme.shadowColor.withValues(alpha: 0.15),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getBorderColor(context),
                width: item.pinned ? 2 : 0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildLeading(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitle(context),
                        const SizedBox(height: 4),
                        _buildSubtitle(context),
                      ],
                    ),
                  ),
                  _buildTrailing(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建前置图标
  Widget _buildLeading() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.pinned)
          const Icon(
            Icons.push_pin,
            color: Colors.amber,
            size: 16,
          ),
        if (item.pinned) const SizedBox(width: 4),
        Icon(
          getIcon(item.category),
          color: getColor(item.category),
        ),
      ],
    );
  }

  /// 构建标题
  Widget _buildTitle(BuildContext context) {
    return Text(
      item.content,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  /// 构建副标题(时间戳)
  Widget _buildSubtitle(BuildContext context) {
    return Text(
      _formatTimestamp(item.timestamp),
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }

  /// 构建尾部操作按钮
  Widget _buildTrailing(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          context,
          icon: Icons.copy_outlined,
          onTap: onCopy,
          tooltip: '复制',
        ),
        const SizedBox(width: 4),
        _buildActionButton(
          context,
          icon: Icons.delete_outline,
          onTap: onDelete,
          tooltip: '删除',
          isDanger: true,
        ),
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool isDanger = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDanger
                ? Theme.of(context).colorScheme.error.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDanger
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  /// 获取背景色
  Color? _getBackgroundColor(BuildContext context) {
    if (isSelected) {
      return Theme.of(context).colorScheme.primary.withValues(alpha: 0.08);
    }
    if (item.pinned) {
      return Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08);
    }
    return Theme.of(context).colorScheme.surface;
  }

  /// 获取边框颜色
  Color _getBorderColor(BuildContext context) {
    if (isSelected) {
      return Theme.of(context).colorScheme.primary;
    }
    if (item.pinned) {
      return Theme.of(context).colorScheme.secondary;
    }
    return Colors.transparent;
  }

  /// 格式化时间戳
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${timestamp.month}月${timestamp.day}日';
    }
  }
}
