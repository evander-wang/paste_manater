import 'package:flutter/material.dart';

/// 空状态视图组件
///
/// 用于显示列表为空时的提示信息和操作指引
class EmptyStateView extends StatelessWidget {
  /// 图标
  final IconData icon;

  /// 标题
  final String title;

  /// 副标题列表
  final List<String> subtitles;

  /// 示例代码(可选)
  final String? exampleCode;

  /// 图标颜色
  final Color? iconColor;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitles,
    this.exampleCode,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: iconColor ?? Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          ..._buildSubtitles(context),
          if (exampleCode != null) ...[
            const SizedBox(height: 16),
            Text(
              '格式示例:',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            _buildExampleCode(),
          ],
        ],
      ),
    );
  }

  /// 构建副标题列表
  List<Widget> _buildSubtitles(BuildContext context) {
    final widgets = <Widget>[];
    for (int i = 0; i < subtitles.length; i++) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        Text(
          subtitles[i],
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      );
    }
    return widgets;
  }

  /// 构建示例代码框
  Widget _buildExampleCode() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        exampleCode!,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
    );
  }
}
