import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/clipboard_item.dart';
import '../models/clipboard_history.dart';
import '../controllers/clipboard_history_controller.dart';
import '../services/clipboard_monitor.dart';
import '../services/storage_service.dart';
import '../services/category_manager.dart';
import '../commons/toast_helper.dart';
import '../commons/category_display_helper.dart';
import 'search_bar_widget.dart';
import 'category_filter_widget.dart';
import 'clipboard_list_item_widget.dart';
import 'clipboard_context_menu.dart';
import 'move_to_category_dialog.dart';
import 'empty_state_view.dart';

/// 剪贴板历史标签页组件
class ClipboardHistoryTab extends StatefulWidget {
  /// 控制器
  final ClipboardHistoryController controller;

  /// 剪贴板监听器
  final ClipboardMonitor clipboardMonitor;

  /// 存储服务
  final StorageService storageService;

  /// 分类管理器
  final CategoryManager categoryManager;

  const ClipboardHistoryTab({
    super.key,
    required this.controller,
    required this.clipboardMonitor,
    required this.storageService,
    required this.categoryManager,
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
                      selectedCategoryId: widget.controller.selectedCategoryId,
                      categoryCounts: _convertCategoryCounts(),
                      totalCount: widget.controller.totalCount,
                      categoryManager: widget.categoryManager,
                      onCategoryToggle: (categoryId) {
                        widget.controller.toggleCategory(categoryId, (fn) => setState(fn));
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
                ToastHelper.show(context, '🗑️ 历史已清空');
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
      onTap: () => _selectItem(item, context),
      onDoubleTap: () => _copyToClipboard(item, context),
      onLongPress: () => _showContextMenu(item, context),
      onCopy: () => _copyToClipboard(item, context),
      onDelete: () => _deleteItem(item, context),
      getIcon: (categoryId) => CategoryDisplayHelper.getIcon(categoryId, widget.categoryManager),
      getColor: (categoryId) => CategoryDisplayHelper.getColor(categoryId, widget.categoryManager),
    );
  }

  /// 选中项目
  void _selectItem(ClipboardItem item, BuildContext context) {
    final filtered = widget.controller.filteredHistory;
    final index = filtered.items.indexOf(item);
    if (index >= 0) {
      widget.controller.setSelectedIndex(index);
    }
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
      ToastHelper.showSuccess(context, '已复制: $preview');
    }
  }

  /// 删除项目
  Future<void> _deleteItem(ClipboardItem item, BuildContext context) async {
    await widget.controller.deleteItem(item);
    if (mounted) {
      ToastHelper.show(context, '🗑️ 已删除');
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
        onMoveToCategory: () => _handleMoveToCategory(item, context),
      ),
    );
  }

  /// 处理置顶切换
  Future<void> _handleTogglePin(ClipboardItem item, BuildContext context) async {
    final pinStateText = item.pinned ? '已取消置顶' : '已置顶';

    try {
      if (item.pinned) {
        await widget.storageService.unpinItem(item.id);
      } else {
        await widget.storageService.pinItem(item.id);
      }
      await widget.controller.loadHistory();
      if (mounted) {
        ToastHelper.show(context, pinStateText);
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, '操作失败: $e');
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

  /// 转换分类计数从 Map<Category, int> 到 Map<String, int>
  Map<String, int> _convertCategoryCounts() {
    return widget.controller.categoryCounts;
  }

  /// 处理移动到分类
  Future<void> _handleMoveToCategory(ClipboardItem item, BuildContext context) async {
    final targetCategoryId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => MoveToCategoryDialog(
        categoryManager: widget.categoryManager,
        currentCategoryId: item.categoryId,
      ),
    );

    if (targetCategoryId != null && mounted) {
      try {
        // 获取当前历史列表
        final history = await widget.storageService.load();
        final historyList = history.items.map((item) => item.toJson()).toList();

        // 调用 CategoryManager 移动项目
        await widget.categoryManager.moveItemToCategory(
          historyList,
          item.id,
          targetCategoryId,
        );

        // 更新历史记录
        final updatedHistory = ClipboardHistory(
          initialItems: historyList.map((json) => ClipboardItem.fromJson(json)).toList(),
          maxItems: history.maxItems,
          maxSize: history.maxSize,
        );

        // 保存更新后的历史列表
        await widget.storageService.save(updatedHistory);

        // 刷新UI
        await widget.controller.loadHistory();

        if (mounted) {
          ToastHelper.showSuccess(context, '已移动到分类');
        }
      } on Exception catch (e) {
        if (mounted) {
          ToastHelper.showError(context, '移动失败: $e');
        }
      }
    }
  }
}
