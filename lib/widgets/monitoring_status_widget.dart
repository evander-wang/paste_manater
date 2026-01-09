import 'package:flutter/material.dart';
import 'dart:async';

/// 监听状态显示组件
///
/// 显示当前剪贴板监听状态（监听中/已停止），带有视觉指示器
class MonitoringStatusWidget extends StatefulWidget {
  /// 是否正在监听
  final bool isMonitoring;

  const MonitoringStatusWidget({
    Key? key,
    required this.isMonitoring,
  }) : super(key: key);

  @override
  State<MonitoringStatusWidget> createState() => _MonitoringStatusWidgetState();
}

class _MonitoringStatusWidgetState extends State<MonitoringStatusWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isMonitoring) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MonitoringStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMonitoring) {
      _animationController.repeat(reverse: true);
    } else {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.isMonitoring ? Colors.green : Colors.grey;
    final statusText = widget.isMonitoring ? '监听中' : '已停止';
    final statusIcon = widget.isMonitoring ? Icons.graphic_eq : Icons.stop;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 状态指示器（带动画）
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: widget.isMonitoring ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        // 状态文本
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 4),
        // 状态图标
        Icon(
          statusIcon,
          color: statusColor,
          size: 16,
        ),
      ],
    );
  }
}
