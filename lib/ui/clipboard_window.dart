import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/clipboard_history.dart';
import '../models/clipboard_item.dart';
import '../models/category.dart';
import '../services/storage_service.dart';

/// 剪贴板管理器主窗口
///
/// 提供剪贴板历史显示、搜索和粘贴功能
class ClipboardWindow extends StatefulWidget {
  final StorageService? storageService;

  const ClipboardWindow({
    super.key,
    this.storageService,
  });

  /// 显示窗口（公共接口）
  static void showWindow(BuildContext context, ClipboardWindow window) {
    // 通过key访问state
    // 实际使用时，需要保持对state的引用
  }

  @override
  State<ClipboardWindow> createState() => ClipboardWindowState();
}

class ClipboardWindowState extends State<ClipboardWindow>
    with SingleTickerProviderStateMixin {
  /// 窗口是否可见
  bool _isVisible = false;

  /// 剪贴板历史
  ClipboardHistory _history = ClipboardHistory();

  /// 当前选中的分类过滤
  Category? _selectedCategory;

  /// 搜索关键词
  String _searchQuery = '';

  /// 当前选中的项目索引
  int? _selectedIndex;

  /// 过滤后的项目列表
  List<ClipboardItem> _filteredItems = [];

  /// 滚动控制器
  final ScrollController _scrollController = ScrollController();

  /// 动画控制器
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  /// 焦点节点
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // 初始化动画
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 加载历史
    _loadHistory();

    // 监听键盘事件（Escape键关闭窗口）
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // 窗口获得焦点
      }
    });

    RawKeyboard.instance.addListener(_handleKeyEvent);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    super.dispose();
  }

  /// 加载剪贴板历史
  Future<void> _loadHistory() async {
    if (widget.storageService == null) return;

    final history = await widget.storageService!.load();
    if (mounted) {
      setState(() {
        _history = history;
        _updateFilteredItems();
      });
    }
  }

  /// 更新过滤后的项目列表
  void _updateFilteredItems() {
    var items = _history.items;

    // 分类过滤
    if (_selectedCategory != null) {
      items = items.where((item) => item.category == _selectedCategory).toList();
    }

    // 搜索过滤
    if (_searchQuery.isNotEmpty) {
      items = items
          .where((item) =>
              item.content.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    setState(() {
      _filteredItems = items;
      // 重置选中索引
      if (_filteredItems.isNotEmpty) {
        _selectedIndex = _selectedIndex != null && _selectedIndex! < _filteredItems.length
            ? _selectedIndex
            : 0;
      } else {
        _selectedIndex = null;
      }
    });
  }

  /// 显示窗口
  void show() {
    setState(() {
      _isVisible = true;
      _selectedIndex = _filteredItems.isNotEmpty ? 0 : null;
    });
    _animationController.forward();
    _focusNode.requestFocus();
  }

  /// 隐藏窗口
  void hide() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isVisible = false;
          _selectedIndex = null;
        });
      }
    });
  }

  /// 切换窗口显示状态
  void toggle() {
    if (_isVisible) {
      hide();
    } else {
      show();
    }
  }

  /// 处理键盘事件
  void _handleKeyEvent(RawKeyEvent event) {
    if (!_isVisible) return;

    if (event is RawKeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.escape:
          hide();
          break;
        case LogicalKeyboardKey.arrowDown:
          _navigateDown();
          break;
        case LogicalKeyboardKey.arrowUp:
          _navigateUp();
          break;
        case LogicalKeyboardKey.enter:
          _selectAndCopyItem();
          break;
        case LogicalKeyboardKey.pageDown:
          _navigatePageDown();
          break;
        case LogicalKeyboardKey.pageUp:
          _navigatePageUp();
          break;
        case LogicalKeyboardKey.home:
          _navigateToStart();
          break;
        case LogicalKeyboardKey.end:
          _navigateToEnd();
          break;
        default:
          break;
      }
    }
  }

  /// 向下导航
  void _navigateDown() {
    if (_filteredItems.isEmpty) return;
    if (_selectedIndex == null) {
      setState(() {
        _selectedIndex = 0;
      });
    } else if (_selectedIndex! < _filteredItems.length - 1) {
      setState(() {
        _selectedIndex = _selectedIndex! + 1;
      });
      _scrollToSelected();
    }
  }

  /// 向上导航
  void _navigateUp() {
    if (_filteredItems.isEmpty) return;
    if (_selectedIndex == null || _selectedIndex! > 0) {
      setState(() {
        _selectedIndex = _selectedIndex != null ? _selectedIndex! - 1 : 0;
      });
      _scrollToSelected();
    }
  }

  /// 页面向下
  void _navigatePageDown() {
    if (_filteredItems.isEmpty) return;
    const pageSize = 10;
    setState(() {
      _selectedIndex = (_selectedIndex! + pageSize).clamp(0, _filteredItems.length - 1);
    });
    _scrollToSelected();
  }

  /// 页面向上
  void _navigatePageUp() {
    if (_filteredItems.isEmpty) return;
    const pageSize = 10;
    setState(() {
      _selectedIndex = (_selectedIndex! - pageSize).clamp(0, _filteredItems.length - 1);
    });
    _scrollToSelected();
  }

  /// 跳转到开始
  void _navigateToStart() {
    if (_filteredItems.isEmpty) return;
    setState(() {
      _selectedIndex = 0;
    });
    _scrollToSelected();
  }

  /// 跳转到末尾
  void _navigateToEnd() {
    if (_filteredItems.isEmpty) return;
    setState(() {
      _selectedIndex = _filteredItems.length - 1;
    });
    _scrollToSelected();
  }

  /// 滚动到选中项目
  void _scrollToSelected() {
    if (_selectedIndex == null) return;

    // 计算目标位置
    final targetOffset = (_selectedIndex! * 72.0); // 假设每个项目高度约为72
    final currentOffset = _scrollController.hasClients ? _scrollController.offset.toDouble() : 0.0;

    // 滚动到可见区域
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  /// 选择并复制项目
  void _selectAndCopyItem() async {
    if (_selectedIndex == null || _filteredItems.isEmpty) return;

    final item = _filteredItems[_selectedIndex!];

    // 复制到剪贴板
    await Clipboard.setData(ClipboardData(text: item.content));

    // 关闭窗口
    hide();
  }

  /// 点击项目选择并复制
  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    final item = _filteredItems[index];

    // 复制到剪贴板
    await Clipboard.setData(ClipboardData(text: item.content));

    // 关闭窗口
    hide();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: GestureDetector(
            onTap: () {
              _focusNode.requestFocus();
            },
            child: Container(
              width: 600,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  _buildSearchBar(),
                  _buildCategoryFilter(),
                  Expanded(
                    child: _buildHistoryList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建窗口头部
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.content_copy,
            size: 20,
            color: Colors.blueGrey,
          ),
          const SizedBox(width: 8),
          const Text(
            '剪贴板历史',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const Spacer(),
          Text(
            '${_history.totalCount} 项',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: TextField(
        autofocus: false,
        decoration: InputDecoration(
          hintText: '搜索剪贴板历史...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                    _updateFilteredItems();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _updateFilteredItems();
        },
      ),
    );
  }

  /// 构建分类过滤器
  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildCategoryChip(null, '全部'),
            const SizedBox(width: 8),
            ...Category.values.map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildCategoryChip(
                  category,
                  _getCategoryDisplayName(category),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 构建分类过滤器按钮
  Widget _buildCategoryChip(Category? category, String label) {
    final isSelected = _selectedCategory == category;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
        _updateFilteredItems();
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? Colors.blue[700] : Colors.grey[700],
      ),
    );
  }

  /// 构建历史列表
  Widget _buildHistoryList() {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.content_copy,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '没有剪贴板历史',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        final isSelected = _selectedIndex == index;
        return _buildHistoryItem(item, index, isSelected);
      },
    );
  }

  /// 构建历史项
  Widget _buildHistoryItem(ClipboardItem item, int index, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[50] : Colors.white,
        border: Border.all(
          color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ListTile(
        leading: Icon(
          _getCategoryIcon(item.category),
          color: _getCategoryColor(item.category),
          size: 20,
        ),
        title: Text(
          item.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue[900] : Colors.black,
          ),
        ),
        subtitle: Text(
          _formatTimestamp(item.timestamp),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                size: 20,
                color: Colors.blue[700],
              )
            : Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.grey[400],
              ),
        onTap: () => _onItemTapped(index),
      ),
    );
  }

  /// 获取分类显示名称
  String _getCategoryDisplayName(Category category) {
    switch (category) {
      case Category.text:
        return '文本';
      case Category.image:
        return '图像';
      case Category.link:
        return '链接';
      case Category.code:
        return '代码';
      case Category.file:
        return '文件';
    }
  }

  /// 获取分类图标
  IconData _getCategoryIcon(Category category) {
    switch (category) {
      case Category.text:
        return Icons.text_snippet;
      case Category.image:
        return Icons.image;
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
      case Category.image:
        return Colors.purple;
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

  /// 窗口是否可见
  bool get isVisible => _isVisible;

  /// 当前选中的项目
  ClipboardItem? get selectedItem =>
      _selectedIndex != null && _selectedIndex! < _filteredItems.length
          ? _filteredItems[_selectedIndex!]
          : null;
}

