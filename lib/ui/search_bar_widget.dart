import 'package:flutter/material.dart';

/// 搜索栏组件
class SearchBarWidget extends StatelessWidget {
  /// 当前搜索关键词
  final String searchQuery;

  /// 搜索关键词变化回调
  final ValueChanged<String> onChanged;

  /// 清除搜索回调
  final VoidCallback onClear;

  /// 点击回调(用于清除选中状态)
  final VoidCallback? onTap;

  const SearchBarWidget({
    super.key,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索剪贴板历史...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
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
        onChanged: onChanged,
        onTap: onTap,
      ),
    );
  }
}
