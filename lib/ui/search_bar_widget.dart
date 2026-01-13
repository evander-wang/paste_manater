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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索剪贴板历史...',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            size: 18,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                  padding: EdgeInsets.zero,
                )
              : null,
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          isDense: true,
        ),
        onChanged: onChanged,
        onTap: onTap,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}
