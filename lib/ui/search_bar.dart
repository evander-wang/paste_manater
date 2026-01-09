import 'dart:async';
import 'package:flutter/material.dart';

/// 搜索栏组件
///
/// 提供文本输入、清除按钮和防抖功能
class SearchBar extends StatefulWidget {
  /// 初始搜索文本
  final String initialText;

  /// 搜索提示文本
  final String hintText;

  /// 搜索回调函数（带防抖延迟）
  final ValueChanged<String>? onSearch;

  /// 清除回调函数
  final VoidCallback? onClear;

  /// 防抖延迟（毫秒）
  final int debounceDelay;

  /// 是否显示清除按钮
  final bool showClearButton;

  /// 文本输入控制器
  final TextEditingController? controller;

  const SearchBar({
    super.key,
    this.initialText = '',
    this.hintText = '搜索...',
    this.onSearch,
    this.onClear,
    this.debounceDelay = 300,
    this.showClearButton = true,
    this.controller,
  });

  @override
  State<SearchBar> createState() => SearchBarState();
}

class SearchBarState extends State<SearchBar> {
  late TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  /// 处理文本变化（带防抖）
  void _onTextChanged(String text) {
    // 取消之前的定时器
    _debounceTimer?.cancel();

    // 立即更新UI（显示文本）
    setState(() {});

    // 设置新的定时器
    if (widget.debounceDelay > 0) {
      _debounceTimer = Timer(
        Duration(milliseconds: widget.debounceDelay),
        () => _performSearch(text),
      );
    } else {
      // 无防抖，立即搜索
      _performSearch(text);
    }
  }

  /// 执行搜索
  void _performSearch(String text) {
    widget.onSearch?.call(text);
  }

  /// 清除搜索
  void _clearSearch() {
    _controller.clear();
    widget.onClear?.call();
    widget.onSearch?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: TextField(
        controller: _controller,
        autofocus: false,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: widget.showClearButton && _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: _clearSearch,
                  tooltip: '清除搜索',
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        onChanged: _onTextChanged,
        onSubmitted: _performSearch,
        textInputAction: TextInputAction.search,
      ),
    );
  }

  /// 获取当前搜索文本
  String get searchText => _controller.text;

  /// 设置搜索文本
  void setSearchText(String text) {
    _controller.text = text;
    _onTextChanged(text);
  }

  /// 清除搜索文本
  void clear() {
    _clearSearch();
  }

  /// 聚焦搜索框
  void focus() {
    // 需要FocusNode才能实现
  }

  /// 取消焦点
  void unfocus() {
    // 需要FocusNode才能实现
  }
}
