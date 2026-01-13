import 'package:flutter/material.dart';
import 'package:paste_manager/models/command.dart';
import 'package:paste_manager/services/command_service.dart';

/// CommandListItem - 命令列表项
///
/// 显示单个命令,使用与剪贴板历史记录相同的卡片样式
class CommandListItem extends StatelessWidget {
  final Command command;
  final VoidCallback onTap;
  final CommandService? commandService;

  const CommandListItem({
    super.key,
    required this.command,
    required this.onTap,
    this.commandService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(10),
        elevation: command.pinned ? 3 : 1,
        shadowColor: theme.shadowColor.withValues(alpha: 0.15),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          onLongPress: () => _showContextMenu(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _getBorderColor(context),
                width: command.pinned ? 1 : 0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  _buildLeading(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitle(context),
                        const SizedBox(height: 3),
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
        if (command.pinned)
          Icon(
            Icons.push_pin,
            size: 14,
            color: Colors.amber[700],
          ),
        if (command.pinned)
          const SizedBox(width: 6)
        else
          const SizedBox(width: 20),
        Icon(
          Icons.terminal,
          size: 18,
          color: Colors.blue[400],
        ),
      ],
    );
  }

  /// 构建标题
  Widget _buildTitle(BuildContext context) {
    return Text(
      command.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  /// 构建副标题(命令内容)
  Widget _buildSubtitle(BuildContext context) {
    return Text(
      command.command,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11,
        fontFamily: 'monospace',
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }

  /// 构建尾部复制按钮
  Widget _buildTrailing(BuildContext context) {
    return Tooltip(
      message: '复制',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.copy,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  /// 获取背景色
  Color? _getBackgroundColor(BuildContext context) {
    if (command.pinned) {
      return Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05);
    }
    return Theme.of(context).colorScheme.surface;
  }

  /// 获取边框颜色
  Color _getBorderColor(BuildContext context) {
    if (command.pinned) {
      return Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3);
    }
    return Colors.transparent;
  }

  /// 显示上下文菜单 (右键菜单 / 长按菜单)
  void _showContextMenu(BuildContext context) {
    if (commandService == null) {
      return;
    }

    final isPinned = command.isPinned;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin),
              title: Text(isPinned ? '取消置顶' : '置顶'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  if (isPinned) {
                    await commandService!.unpinCommand(command.id);
                  } else {
                    await commandService!.pinCommand(command.id);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isPinned ? '已取消置顶' : '已置顶'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('操作失败: $e'),
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('复制'),
              onTap: () {
                Navigator.pop(context);
                onTap();
              },
            ),
          ],
        ),
      ),
    );
  }
}
