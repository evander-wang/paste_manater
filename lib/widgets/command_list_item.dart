import 'package:flutter/material.dart';
import 'package:paste_manager/models/command.dart';
import 'package:paste_manager/services/command_service.dart';

/// CommandListItem - 命令列表项
///
/// 显示单个命令,支持点击复制、右键菜单置顶/取消置顶、显示置顶状态
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
    return ListTile(
      leading: _buildLeadingIcon(),
      title: Text(
        command.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        command.command,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'monospace',
          color: Colors.grey[600],
          fontSize: 13,
        ),
      ),
      trailing: _buildTrailingIcon(),
      onTap: onTap,
      onLongPress: () => _showContextMenu(context),
      // 置顶项目使用不同的背景色
      tileColor: command.pinned ? Colors.amber[50] : null,
    );
  }

  /// 构建左侧图标
  Widget _buildLeadingIcon() {
    if (command.pinned) {
      // 置顶图标
      return const Icon(
        Icons.push_pin,
        color: Colors.amber,
        size: 20,
      );
    } else {
      // 默认图标
      return Icon(
        Icons.terminal,
        color: Colors.blue[400],
        size: 20,
      );
    }
  }

  /// 构建右侧图标
  Widget? _buildTrailingIcon() {
    return Icon(
      Icons.copy,
      color: Colors.grey[400],
      size: 20,
    );
  }

  /// 显示上下文菜单 (右键菜单 / 长按菜单)
  void _showContextMenu(BuildContext context) {
    if (commandService == null) {
      // 如果没有提供 commandService,则不显示菜单
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
