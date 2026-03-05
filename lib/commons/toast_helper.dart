import 'package:flutter/material.dart';

/// SnackBar 消息显示辅助工具类
/// 统一处理应用中的消息提示
class ToastHelper {
  /// 显示成功消息（绿色背景，✅ 图标）
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $message'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 显示错误消息（红色背景，❌ 图标）
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// 显示普通消息
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
