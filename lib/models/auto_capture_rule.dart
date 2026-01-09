/// 自动捕获规则配置
///
/// 定义剪贴板自动捕获的行为规则，包括去重窗口、内容长度限制等
class AutoCaptureRule {
  /// 去重时间窗口（在此时间内相同哈希内容视为重复）
  final Duration deduplicationWindow;

  /// 最小内容长度（字符数）
  final int minContentLength;

  /// 最大内容长度（字符数）
  final int maxContentLength;

  /// 是否在应用启动时自动开始监听
  final bool autoStart;

  const AutoCaptureRule({
    this.deduplicationWindow = const Duration(seconds: 5),
    this.minContentLength = 1,
    this.maxContentLength = 10 * 1024 * 1024, // 10MB
    this.autoStart = true,
  });

  /// 验证内容是否符合捕获规则
  ///
  /// 返回 true 表示内容应该被捕获，false 表示应该跳过
  bool shouldCapture(String content) {
    final length = content.length;
    return length >= minContentLength && length <= maxContentLength;
  }

  /// 创建测试用规则
  static const test = AutoCaptureRule(
    deduplicationWindow: Duration(seconds: 1),
    minContentLength: 1,
    maxContentLength: 1024, // 1KB for testing
    autoStart: false,
  );
}
