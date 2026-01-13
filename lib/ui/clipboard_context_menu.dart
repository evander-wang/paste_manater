import 'package:flutter/material.dart';
import '../models/clipboard_item.dart';

/// 剪贴板项目上下文菜单
///
/// 显示置顶、复制、删除等操作选项
class ClipboardContextMenu extends StatelessWidget {
  /// 剪贴板项目
  final ClipboardItem item;

  /// 置顶回调
  final VoidCallback onTogglePin;

  /// 复制回调
  final VoidCallback onCopy;

  /// 删除回调
  final VoidCallback onDelete;

  const ClipboardContextMenu({
    super.key,
    required this.item,
    required this.onTogglePin,
    required this.onCopy,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPinMenuItem(context),
          _buildCopyMenuItem(context),
          _buildDeleteMenuItem(context),
        ],
      ),
    );
  }

  /// 构建置顶菜单项
  Widget _buildPinMenuItem(BuildContext context) {
    final isPinned = item.isPinned;
    return ListTile(
      leading: Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin),
      title: Text(isPinned ? '取消置顶' : '置顶'),
      onTap: () {
        Navigator.pop(context);
        onTogglePin();
      },
    );
  }

  /// 构建复制菜单项
  Widget _buildCopyMenuItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.content_copy),
      title: const Text('复制'),
      onTap: () {
        Navigator.pop(context);
        onCopy();
      },
    );
  }

  /// 构建删除菜单项
  Widget _buildDeleteMenuItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.delete, color: Colors.red),
      title: const Text('删除', style: TextStyle(color: Colors.red)),
      onTap: () {
        Navigator.pop(context);
        onDelete();
      },
    );
  }
}
