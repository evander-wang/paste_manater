import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/clipboard_item.dart';
import '../models/category.dart';
import '../controllers/clipboard_history_controller.dart';
import '../services/clipboard_monitor.dart';
import '../services/storage_service.dart';
import 'search_bar_widget.dart';
import 'category_filter_widget.dart';
import 'clipboard_list_item_widget.dart';
import 'clipboard_context_menu.dart';
import 'empty_state_view.dart';

/// 剪贴板历史标签页组件
class ClipboardHistoryTab extends StatefulWidget {
  /// 控制器
  final ClipboardHistoryController controller;

  /// 剪贴板监听器
  final ClipboardMonitor clipboardMonitor;

  /// 存储服务
  final StorageService storageService;

  const ClipboardHistoryTab({
    super.key,
    required this.controller,
    required this.clipboardMonitor,
    required this.storageService,
  });

  @override
  State<ClipboardHistoryTab> createState() => _ClipboardHistoryTabState();
}

class _ClipboardHistoryTabState extends State<ClipboardHistoryTab> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        return Column(
          children: [
            // 搜索和过滤器区域
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 搜索框
                    SearchBarWidget(
                      searchQuery: widget.controller.searchQuery,
                      onChanged: (query) {
                        widget.controller.onSearchChanged(query, (fn) => setState(fn));
                      },
                      onClear: () {
                        widget.controller.clearSearch((fn) => setState(fn));
                      },
                      onTap: () {
                        widget.controller.resetSelection();
                      },
                    ),
                    // 分类过滤器
                    CategoryFilterWidget(
                      selectedCategory: widget.controller.selectedCategory,
                      categoryCounts: widget.controller.categoryCounts,
                      totalCount: widget.controller.totalCount,
                      getIcon: _getCategoryIcon,
                      getColor: _getCategoryColor,
                      onCategoryToggle: (category) {
                        widget.controller.toggleCategory(category, (fn) => setState(fn));
                      },
                    ),
                    // 统计信息和清空按钮
                    _buildHeader(context),
                    const Divider(),
                    // 历史列表
                    Expanded(
                      child: _buildHistoryList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建头部(统计信息和清空按钮)
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.history, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            '历史记录 (${widget.controller.totalCount} 项)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '↑↓ 选择  Enter 粘贴  Esc 关闭',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () async {
              await widget.controller.clearHistory();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🗑️ 历史已清空')),
                );
              }
            },
            icon: const Icon(Icons.delete_sweep, size: 18),
            label: const Text('清空'),
          ),
        ],
      ),
    );
  }

  /// 构建历史列表
  Widget _buildHistoryList() {
    final filtered = widget.controller.filteredHistory;

    // 情况1: 历史记录完全为空
    if (widget.controller.history.items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: '暂无历史记录',
        subtitle: '复制一些文本,然后点击"获取剪贴板"和"添加到历史"',
      );
    }

    // 情况2: 搜索但没有匹配结果
    if (widget.controller.searchQuery.isNotEmpty && filtered.items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: '未找到匹配项',
        subtitle: '尝试其他关键词',
        iconColor: Colors.orange,
      );
    }

    // 情况3: 正常显示列表
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: ListView.builder(
        itemCount: filtered.items.length,
        itemBuilder: (context, index) {
          final item = filtered.items[index];
          final isSelected = index == widget.controller.selectedIndex;

          return _buildListItem(item, isSelected, context);
        },
      ),
    );
  }

  /// 构建列表项
  Widget _buildListItem(ClipboardItem item, bool isSelected, BuildContext context) {
    return ClipboardListItemWidget(
      item: item,
      isSelected: isSelected,
      onTap: () => _copyToClipboard(item, context),
      onLongPress: () => _showContextMenu(item, context),
      onCopy: () => _copyToClipboard(item, context),
      onDelete: () => _deleteItem(item, context),
      getIcon: _getCategoryIcon,
      getColor: _getCategoryColor,
    );
  }

  /// 处理键盘事件
  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        if (!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
        widget.controller.moveSelectionDown();
        break;

      case LogicalKeyboardKey.arrowUp:
        if (!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
        widget.controller.moveSelectionUp();
        break;

      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        _copySelectedItem(context);
        break;

      case LogicalKeyboardKey.escape:
        Navigator.of(context).pop();
        break;
    }
  }

  /// 复制选中项目
  Future<void> _copySelectedItem(BuildContext context) async {
    final item = await widget.controller.getSelectedItem();
    if (item != null) {
      await _copyToClipboard(item, context);
    }
  }

  /// 复制到剪贴板
  Future<void> _copyToClipboard(ClipboardItem item, BuildContext context) async {
    widget.clipboardMonitor.markOwnCopy(item.content);
    await Clipboard.setData(ClipboardData(text: item.content));

    // 让窗口失去焦点,会自动触发最小化
    try {
      await const MethodChannel('paste_manager/hotkey').invokeMethod('resignFocus');
    } on PlatformException catch (e) {
      debugPrint('失去焦点失败: $e');
    }

    if (mounted) {
      final preview = item.content.length > 20
          ? '${item.content.substring(0, 20)}...'
          : item.content;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ 已复制: $preview'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 删除项目
  Future<void> _deleteItem(ClipboardItem item, BuildContext context) async {
    await widget.controller.deleteItem(item);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ 已删除')),
      );
    }
  }

  /// 显示上下文菜单
  void _showContextMenu(ClipboardItem item, BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ClipboardContextMenu(
        item: item,
        onTogglePin: () => _handleTogglePin(item, context),
        onCopy: () => _copyToClipboard(item, context),
        onDelete: () => _deleteItem(item, context),
      ),
    );
  }

  /// 处理置顶切换
  Future<void> _handleTogglePin(ClipboardItem item, BuildContext context) async {
    try {
      if (item.pinned) {
        await widget.storageService.unpinItem(item.id);
      } else {
        await widget.storageService.pinItem(item.id);
      }
      await widget.controller.loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(item.pinned ? '已取消置顶' : '已置顶'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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
  }

  /// 构建空状态
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
  }) {
    return EmptyStateView(
      icon: icon,
      title: title,
      subtitles: [subtitle],
      iconColor: iconColor,
    );
  }

  /// 获取分类图标
  IconData _getCategoryIcon(Category category) {
    switch (category) {
      case Category.text:
        return Icons.text_snippet;
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
      case Category.link:
        return Colors.blue;
      case Category.code:
        return Colors.green;
      case Category.file:
        return Colors.orange;
    }
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
