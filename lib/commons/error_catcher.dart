import 'package:flutter/foundation.dart';

/// 自定义异常类
class CustomException implements Exception {
  CustomException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 错误处理辅助工具类
/// 统一处理try-catch模式和错误转换
class ErrorCatcher {
  /// 捕获异常并返回默认值
  ///
  /// 参数:
  /// - [defaultValue] 操作失败时返回的默认值
  /// - [operation] 要执行的操作
  ///
  /// 返回: 操作结果或默认值
  static T catchAndReturnDefault<T>(T defaultValue, T Function() operation) {
    try {
      return operation();
    } on Exception catch (e) {
      debugPrint('操作失败: $e');
      return defaultValue;
    }
  }

  /// 捕获异常并重新抛出自定义异常
  ///
  /// 参数:
  /// - [operation] 要执行的操作
  /// - [errorMessage] 自定义错误消息
  ///
  /// 抛出: [CustomException] 包装的异常
  static void catchAndRethrow(void Function() operation, String errorMessage) {
    try {
      operation();
    } on Exception catch (e) {
      throw CustomException('$errorMessage: $e');
    }
  }

  /// 异步捕获异常并返回默认值
  ///
  /// 参数:
  /// - [defaultValue] 操作失败时返回的默认值
  /// - [operation] 要执行的异步操作
  ///
  /// 返回: 操作结果或默认值
  static Future<T> catchAndReturnDefaultAsync<T>(
    T defaultValue,
    Future<T> Function() operation,
  ) async {
    try {
      return await operation();
    } on Exception catch (e) {
      debugPrint('异步操作失败: $e');
      return defaultValue;
    }
  }
}
