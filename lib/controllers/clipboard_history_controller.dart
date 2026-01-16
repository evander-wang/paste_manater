import 'dart:async';
import 'package:flutter/material.dart';
import '../models/clipboard_history.dart';
import '../models/search_query.dart';
import '../models/clipboard_item.dart';
import '../services/storage_service.dart';
import '../services/search_service.dart';
import '../services/pin_service.dart';
import '../services/clipboard_monitor.dart';

/// 剪贴板历史控制器
///
/// 负责管理剪贴板历史的业务逻辑,包括加载、搜索、过滤等
class ClipboardHistoryController extends ChangeNotifier {
  /// 存储服务
  final StorageService storageService;

  /// 剪贴板监听器
  final ClipboardMonitor clipboardMonitor;

  /// 历史记录
  ClipboardHistory _history = ClipboardHistory();

  /// 当前选中项目的索引(-1 表示没有选中)
  int _selectedIndex = -1;

  /// 搜索关键词
  String _searchQuery = '';

  /// 当前选中的分类过滤器 ID (null 表示全部)
  String? _selectedCategoryId;

  /// 搜索防抖定时器
  Timer? _searchDebounceTimer;

  /// 历史记录刷新定时器
  Timer? _historyRefreshTimer;

  /// 获取历史记录
  ClipboardHistory get history => _history;

  /// 获取选中索引
  int get selectedIndex => _selectedIndex;

  /// 获取搜索关键词
  String get searchQuery => _searchQuery;

  /// 获取选中的分类ID
  String? get selectedCategoryId => _selectedCategoryId;

  /// 获取过滤后的历史记录
  ClipboardHistory get filteredHistory => _filteredHistory;

  /// 获取总记录数
  int get totalCount => _history.totalCount;

  /// 获取每个分类的计数
  Map<String, int> get categoryCounts {
    final counts = <String, int>{};
    for (final item in _history.items) {
      counts[item.categoryId] = (counts[item.categoryId] ?? 0) + 1;
    }
    return counts;
  }

  ClipboardHistoryController({
    required this.storageService,
    required this.clipboardMonitor,
  });

  /// 初始化
  Future<void> initialize() async {
    await loadHistory();
    startAutoRefresh();
  }

  /// 销毁
  @override
  void dispose() {
    _historyRefreshTimer?.cancel();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  /// 加载历史记录
  Future<void> loadHistory() async {
    final history = await storageService.load();
    _history = history;
    notifyListeners();
  }

  /// 启动历史记录定时刷新(每2秒)
  void startAutoRefresh() {
    _historyRefreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      loadHistory();
    });
  }

  /// 处理搜索输入(带防抖)
  void onSearchChanged(String query, Function(VoidCallback) setState) {
    _searchDebounceTimer?.cancel();

    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
        _selectedIndex = -1;
      });
      notifyListeners();
    });
  }

  /// 清除搜索
  void clearSearch(Function(VoidCallback) setState) {
    _searchDebounceTimer?.cancel();
    setState(() {
      _searchQuery = '';
      _selectedIndex = -1;
    });
    notifyListeners();
  }

  /// 切换分类过滤
  void toggleCategory(String? categoryId, Function(VoidCallback) setState) {
    setState(() {
      if (_selectedCategoryId == categoryId) {
        _selectedCategoryId = null;
      } else {
        _selectedCategoryId = categoryId;
      }
      _selectedIndex = -1;
    });
    notifyListeners();
  }

  /// 处理键盘导航 - 向下
  void moveSelectionDown() {
    final filtered = filteredHistory;
    if (filtered.items.isEmpty) return;

    if (_selectedIndex < filtered.items.length - 1) {
      _selectedIndex++;
    } else {
      _selectedIndex = 0; // 循环到第一个
    }
    notifyListeners();
  }

  /// 处理键盘导航 - 向上
  void moveSelectionUp() {
    final filtered = filteredHistory;
    if (filtered.items.isEmpty) return;

    if (_selectedIndex > 0) {
      _selectedIndex--;
    } else {
      _selectedIndex = filtered.items.length - 1; // 循环到最后一个
    }
    notifyListeners();
  }

  /// 重置选中状态
  void resetSelection() {
    _selectedIndex = -1;
    notifyListeners();
  }

  /// 复制选中项目
  Future<ClipboardItem?> getSelectedItem() async {
    if (_selectedIndex >= 0 && _selectedIndex < filteredHistory.items.length) {
      return filteredHistory.items[_selectedIndex];
    }
    return null;
  }

  /// 删除项目
  Future<void> deleteItem(ClipboardItem item) async {
    final updatedHistory = _history.remove(item.id);
    await storageService.save(updatedHistory);
    await loadHistory();
  }

  /// 清空历史
  Future<void> clearHistory() async {
    await storageService.clear();
    await loadHistory();
  }

  /// 获取过滤后的历史记录(私有方法)
  ClipboardHistory get _filteredHistory {
    var results = _history.items.toList();

    // 1. 先应用分类过滤
    if (_selectedCategoryId != null) {
      results = results.where((item) => item.categoryId == _selectedCategoryId).toList();
    }

    // 2. 再应用搜索过滤
    if (_searchQuery.isNotEmpty) {
      final searchService = SearchService();
      final queryObj = SearchQuery(query: _searchQuery);
      results = searchService.search(ClipboardHistory(initialItems: results), queryObj);
    }

    // 3. 应用置顶排序(置顶项目在前,按置顶时间倒序)
    final pinService = PinService();
    results = pinService.sortByPinStatus(results);

    return ClipboardHistory(initialItems: results);
  }
}
