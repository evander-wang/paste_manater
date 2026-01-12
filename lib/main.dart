import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/category.dart';
import 'models/clipboard_item.dart';
import 'models/clipboard_history.dart';
import 'models/search_query.dart';
import 'services/storage_service.dart';
import 'services/clipboard_monitor.dart';
import 'services/hotkey_manager.dart';
import 'services/search_service.dart';
import 'services/pin_service.dart';
import 'widgets/monitoring_status_widget.dart';
import 'widgets/command_tab.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化服务
  final storageService = StorageService();
  final clipboardMonitor = ClipboardMonitor(
    storageService: storageService,
  );

  // 初始化热键管理器
  final hotkeyManager = HotkeyManager(
    storageService: storageService,
  );

  runApp(PasteManagerApp(
    clipboardMonitor: clipboardMonitor,
    hotkeyManager: hotkeyManager,
    storageService: storageService,
  ));
}

class PasteManagerApp extends StatefulWidget {
  final ClipboardMonitor clipboardMonitor;
  final HotkeyManager hotkeyManager;
  final StorageService storageService;

  const PasteManagerApp({
    Key? key,
    required this.clipboardMonitor,
    required this.hotkeyManager,
    required this.storageService,
  }) : super(key: key);

  @override
  State<PasteManagerApp> createState() => _PasteManagerAppState();
}

class _PasteManagerAppState extends State<PasteManagerApp>
    with SingleTickerProviderStateMixin {
  // 剪贴板历史
  ClipboardHistory _history = ClipboardHistory();

  // TabController
  late TabController _tabController;

  // 是否正在监听
  bool _isMonitoring = false;

  // 当前选中项目的索引（-1 表示没有选中）
  int _selectedIndex = -1;

  // 搜索关键词
  String _searchQuery = '';

  // 搜索防抖定时器
  Timer? _searchDebounceTimer;

  // 定时刷新历史记录
  Timer? _historyRefreshTimer;

  // 监听状态流订阅
  StreamSubscription<bool>? _statusSubscription;

  // 全局键盘焦点节点
  final FocusNode _focusNode = FocusNode();

  // 当前选中的分类过滤器（null 表示全部）
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // 初始化 TabController (2个标签页)
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
    _startAutoMonitoring();
    _startHistoryRefresh();
    _listenToStatusChanges();
    // 自动注册热键
    _registerHotkey();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _historyRefreshTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _statusSubscription?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  /// 监听监听状态变化
  void _listenToStatusChanges() {
    _statusSubscription = widget.clipboardMonitor.statusStream.listen((isMonitoring) {
      if (mounted) {
        setState(() {
          _isMonitoring = isMonitoring;
        });
      }
    });
  }

  /// 自动启动监听
  Future<void> _startAutoMonitoring() async {
    try {
      await widget.clipboardMonitor.startAuto();
      setState(() {
        _isMonitoring = true;
      });
      print('✅ 应用启动时自动开启剪贴板监听');
    } catch (e) {
      debugPrint('自动启动监听失败: $e');
    }
  }

  /// 自动注册热键
  Future<void> _registerHotkey() async {
    try {
      await widget.hotkeyManager.register(
        HotkeyManager.defaultHotkey,
        () {
          debugPrint('热键触发：Cmd+Shift+V');
        },
      );
      print('✅ 热键已自动注册：Cmd+Shift+V（显示/隐藏窗口）');
    } catch (e) {
      debugPrint('热键注册失败: $e');
    }
  }

  /// 启动历史记录定时刷新（每2秒）
  void _startHistoryRefresh() {
    _historyRefreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadHistory();
    });
  }

  /// 加载历史记录
  Future<void> _loadHistory() async {
    final history = await widget.storageService.load();
    setState(() {
      _history = history;
    });
  }

  /// 处理搜索输入（带防抖）
  void _onSearchChanged(String query) {
    // 取消之前的防抖定时器
    _searchDebounceTimer?.cancel();

    // 设置新的防抖定时器（300ms）
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
        // 搜索时重置选中状态
        _selectedIndex = -1;
      });
    });
  }

  /// 清除搜索
  void _clearSearch() {
    _searchDebounceTimer?.cancel();
    setState(() {
      _searchQuery = '';
      _selectedIndex = -1;
    });
  }

  /// 切换分类过滤
  void _toggleCategory(Category? category) {
    setState(() {
      // 如果点击的是当前选中的分类，则取消过滤
      if (_selectedCategory == category) {
        _selectedCategory = null;
      } else {
        _selectedCategory = category;
      }
      // 切换分类时重置选中状态
      _selectedIndex = -1;
    });
  }

  /// 获取过滤后的历史记录
  ClipboardHistory get _filteredHistory {
    var results = _history.items.toList();

    // 1. 先应用分类过滤
    if (_selectedCategory != null) {
      results = results.where((item) => item.category == _selectedCategory).toList();
    }

    // 2. 再应用搜索过滤
    if (_searchQuery.isNotEmpty) {
      final searchService = SearchService();
      final queryObj = SearchQuery(query: _searchQuery);
      results = searchService.search(ClipboardHistory(initialItems: results), queryObj);
    }

    // 3. 应用置顶排序 (置顶项目在前,按置顶时间倒序)
    final pinService = PinService();
    results = pinService.sortByPinStatus(results);

    return ClipboardHistory(initialItems: results);
  }

  /// 获取每个分类的计数
  Map<Category, int> get _categoryCounts {
    final counts = <Category, int>{};
    for (final item in _history.items) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return counts;
  }

  /// 处理键盘事件
  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final filtered = _filteredHistory;

    // 如果历史为空，不处理键盘事件
    if (filtered.items.isEmpty) return;

    // 只处理方向键、Enter、Escape，不干扰搜索框输入
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        // 确保焦点在 KeyboardListener 上
        if (!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
        setState(() {
          if (_selectedIndex < filtered.items.length - 1) {
            _selectedIndex++;
          } else {
            // 循环到第一个
            _selectedIndex = 0;
          }
        });
        break;

      case LogicalKeyboardKey.arrowUp:
        if (!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
        setState(() {
          if (_selectedIndex > 0) {
            _selectedIndex--;
          } else {
            // 循环到最后一个
            _selectedIndex = filtered.items.length - 1;
          }
        });
        break;

      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        _copySelectedItem();
        break;

      case LogicalKeyboardKey.escape:
        _closeWindow();
        break;
    }
  }

  /// 复制选中的项目到剪贴板并关闭窗口
  Future<void> _copySelectedItem() async {
    final filtered = _filteredHistory;
    if (_selectedIndex >= 0 && _selectedIndex < filtered.items.length) {
      final item = filtered.items[_selectedIndex];

      // 标记为自己的复制操作，避免被监听器记录
      widget.clipboardMonitor.markOwnCopy(item.content);

      await Clipboard.setData(ClipboardData(text: item.content));

      final preview = item.content.length > 20
          ? '${item.content.substring(0, 20)}...'
          : item.content;
      print('✅ 已复制选中项 ($preview)');

      await _closeWindow();
    }
  }

  /// 关闭窗口（最小化到 Dock）
  Future<void> _closeWindow() async {
    try {
      await widget.hotkeyManager.toggleWindow();
    } catch (e) {
      print('❌ 关闭窗口失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '智能剪贴板管理器',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('智能剪贴板管理器'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            actions: [
              // 状态显示组件
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: MonitoringStatusWidget(
                    isMonitoring: _isMonitoring,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadHistory,
                tooltip: '刷新历史',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: '剪贴板历史', icon: Icon(Icons.history)),
                Tab(text: '常用命令', icon: Icon(Icons.terminal)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // 第一个标签页: 剪贴板历史 (原有内容)
              _buildClipboardHistoryTab(),
              // 第二个标签页: 常用命令
              CommandTab(clipboardMonitor: widget.clipboardMonitor),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建剪贴板历史标签页
  Widget _buildClipboardHistoryTab() {
    return Column(
      children: [
        // 历史记录区域
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 搜索框
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '搜索剪贴板历史...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: _onSearchChanged,
                    onTap: () {
                      // 用户点击搜索框时,清除选中状态
                      setState(() {
                        _selectedIndex = -1;
                      });
                    },
                  ),
                ),
                // 分类过滤器
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // "全部"按钮
                      _buildCategoryButton(null, '全部', _history.totalCount),
                      // 各个分类按钮
                      ...Category.values.map((category) {
                        final count = _categoryCounts[category] ?? 0;
                        return _buildCategoryButton(
                          category,
                          _getCategoryLabel(category),
                          count,
                        );
                      }),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        '历史记录 (${_history.totalCount} 项)',
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
                      Builder(
                        builder: (BuildContext builderContext) {
                          return TextButton.icon(
                            onPressed: () async {
                              await widget.storageService.clear();
                              await _loadHistory();
                              if (mounted) {
                                  ScaffoldMessenger.of(builderContext).showSnackBar(
                                  const SnackBar(content: Text('🗑️ 历史已清空')),
                                );
                              }
                            },
                            icon: const Icon(Icons.delete_sweep, size: 18),
                            label: const Text('清空'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _buildHistoryList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建历史列表（包含搜索和空状态处理）
  Widget _buildHistoryList() {
    final filtered = _filteredHistory;

    // 情况1：历史记录完全为空
    if (_history.items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.history,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                '暂无历史记录',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '复制一些文本，然后点击"获取剪贴板"和"添加到历史"',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // 情况2：搜索但没有匹配结果
    if (_searchQuery.isNotEmpty && filtered.items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off,
                size: 48,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                '未找到匹配项',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '尝试其他关键词',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 情况3：正常显示列表
    return ListView.builder(
      itemCount: filtered.items.length,
      itemBuilder: (context, index) {
        final item = filtered.items[index];
        final isSelected = index == _selectedIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Card(
            key: ValueKey(item.id),
            margin: const EdgeInsets.symmetric(vertical: 4),
            elevation: isSelected ? 4 : 1,
            color: isSelected ? Colors.blue.shade50 : (item.pinned ? Colors.amber[50] : null),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isSelected ? Colors.blue : (item.pinned ? Colors.amber : Colors.transparent),
                width: item.pinned ? 2 : 1,
              ),
            ),
            child: Builder(
              builder: (BuildContext listTileContext) {
              return ListTile(
                selected: isSelected,
                onLongPress: () => _showClipboardContextMenu(item, listTileContext),
                leading: Row(
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
                      _getCategoryIcon(item.category),
                      color: _getCategoryColor(item.category),
                    ),
                  ],
                ),
                title: _buildItemTitle(item, isSelected),
                subtitle: Text(
                  _formatTimestamp(item.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                trailing: Builder(
                  builder: (BuildContext builderContext) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () async {
                            // 标记为自己的复制操作，避免被监听器记录
                            widget.clipboardMonitor.markOwnCopy(item.content);

                            await Clipboard.setData(
                              ClipboardData(text: item.content),
                            );
                            if (mounted) {
                              final preview = item.content.length > 20
                                  ? '${item.content.substring(0, 20)}...'
                                  : item.content;
                              ScaffoldMessenger.of(builderContext).showSnackBar(
                                SnackBar(
                                  content: Text('✅ 已复制: $preview'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          tooltip: '复制到剪贴板',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: () async {
                            // 从历史中移除项目
                            final updatedHistory = _history.remove(item.id);
                            await widget.storageService.save(updatedHistory);
                            await _loadHistory();
                            if (mounted) {
                              ScaffoldMessenger.of(builderContext).showSnackBar(
                                const SnackBar(content: Text('🗑️ 已删除')),
                              );
                            }
                          },
                          tooltip: '删除',
                        ),
                      ],
                    );
                  },
                ),
                onTap: () async {
                  // 标记为自己的复制操作，避免被监听器记录
                  widget.clipboardMonitor.markOwnCopy(item.content);

                  await Clipboard.setData(
                    ClipboardData(text: item.content),
                  );
                  if (mounted) {
                    final preview = item.content.length > 20
                        ? '${item.content.substring(0, 20)}...'
                        : item.content;
                    ScaffoldMessenger.of(listTileContext).showSnackBar(
                      SnackBar(
                        content: Text('✅ 已复制: $preview'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
      );
    },
  );
  }

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

  /// 构建分类按钮
  Widget _buildCategoryButton(Category? category, String label, int count) {
    final isSelected = _selectedCategory == category;
    final icon = category != null ? _getCategoryIcon(category) : Icons.apps;
    final color = category != null ? _getCategoryColor(category) : Colors.grey;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (category != null) ...[
            Icon(icon, size: 16, color: isSelected ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Text(label),
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => _toggleCategory(category),
      selectedColor: color,
      backgroundColor: Colors.grey[100],
      checkmarkColor: Colors.white,
      elevation: isSelected ? 4 : 0,
    );
  }

  /// 获取分类的中文标签
  String _getCategoryLabel(Category category) {
    switch (category) {
      case Category.text:
        return '文本';
      case Category.link:
        return '链接';
      case Category.code:
        return '代码';
      case Category.file:
        return '文件';
    }
  }

  /// 构建项目标题
  Widget _buildItemTitle(ClipboardItem item, bool isSelected) {
    return Text(
      item.content,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  /// 显示剪贴板项目的上下文菜单 (置顶/取消置顶)
  void _showClipboardContextMenu(ClipboardItem item, BuildContext context) {
    final isPinned = item.isPinned;

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
                    await widget.storageService.unpinItem(item.id);
                  } else {
                    await widget.storageService.pinItem(item.id);
                  }
                  await _loadHistory();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isPinned ? '已取消置顶' : '已置顶'),
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
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('复制'),
              onTap: () async {
                Navigator.pop(context);
                // 标记为自己的复制操作，避免被监听器记录
                widget.clipboardMonitor.markOwnCopy(item.content);

                await Clipboard.setData(
                  ClipboardData(text: item.content),
                );
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
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                // 从历史中移除项目
                final updatedHistory = _history.remove(item.id);
                await widget.storageService.save(updatedHistory);
                await _loadHistory();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🗑️ 已删除')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
