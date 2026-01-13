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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Card(
        key: ValueKey(item.id),
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: isSelected ? 4 : 1,
        color: _getBackgroundColor(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: _getBorderColor(),
            width: item.pinned ? 2 : 1,
          ),
        ),
        child: ListTile(
          selected: isSelected,
          onLongPress: onLongPress,
          leading: _buildLeading(),
          title: _buildTitle(),
          subtitle: _buildSubtitle(),
          trailing: _buildTrailing(context),
          onTap: onTap,
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
  Widget _buildTitle() {
    return Text(
      item.content,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  /// 构建副标题(时间戳)
  Widget _buildSubtitle() {
    return Text(
      _formatTimestamp(item.timestamp),
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      ),
    );
  }

  /// 构建尾部操作按钮
  Widget _buildTrailing(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.copy, size: 18),
          onPressed: onCopy,
          tooltip: '复制到剪贴板',
        ),
        IconButton(
          icon: const Icon(Icons.delete, size: 18),
          onPressed: onDelete,
          tooltip: '删除',
        ),
      ],
    );
  }

  /// 获取背景色
  Color? _getBackgroundColor() {
    if (isSelected) return Colors.blue.shade50;
    if (item.pinned) return Colors.amber[50];
    return null;
  }

  /// 获取边框颜色
  Color _getBorderColor() {
    if (isSelected) return Colors.blue;
    if (item.pinned) return Colors.amber;
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
