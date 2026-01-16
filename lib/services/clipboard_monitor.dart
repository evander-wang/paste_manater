import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import '../models/clipboard_item.dart';
import '../models/category.dart';
import '../models/clipboard_history.dart' as models;
import '../models/auto_capture_rule.dart';
import '../services/storage_service.dart';
import '../services/category_detector.dart';

/// 剪贴板监听服务
///
/// 提供系统剪贴板轮询和变更检测功能
class ClipboardMonitor {
  /// 存储服务
  final StorageService storageService;

  /// 轮询间隔（0.5 秒）
  final Duration checkInterval;

  /// 被忽略的应用（密码管理器）
  final List<String> _ignoredApps;

  /// Method Channel 用于 macOS 原生剪贴板访问
  static const _platform = MethodChannel('paste_manager/clipboard');

  /// 当前剪贴板数据
  String? _currentData;

  /// 当前变更计数
  int? _currentChangeCount;

  /// 监听计时器
  Timer? _monitorTimer;

  /// 是否正在监听
  bool _isMonitoring = false;

  /// 监听状态流（用于 UI 更新）
  final StreamController<bool> _statusController = StreamController<bool>.broadcast();

  /// 监听状态流
  Stream<bool> get statusStream => _statusController.stream;

  /// 自动捕获规则
  AutoCaptureRule? _captureRule;

  /// 去重缓存（哈希 -> 最后见到的时间）
  final Map<String, DateTime> _recentHashes = {};

  /// 是否有待处理的自己的复制操作（标志位，用于跳过下一次剪贴板检测）
  bool _isPendingOwnCopy = false;

  /// 性能监控计时器
  final Stopwatch _captureStopwatch = Stopwatch();

  /// 密码管理器黑名单
  static const List<String> passwordManagerBlacklist = [
    'com.agilebits.onepassword7',
    'com.bitwarden.desktop',
    'com.1password.1password',
  ];

  ClipboardMonitor({
    required this.storageService,
    this.checkInterval = const Duration(milliseconds: 500),
    List<String>? ignoredApps,
  }) : _ignoredApps = ignoredApps ?? passwordManagerBlacklist;

  /// 启动监听
  Future<void> start() async {
    if (_isMonitoring) {
      return;
    }

    _isMonitoring = true;
    _statusController.add(true); // 发送状态更新

    // 启动原生监听器
    try {
      await _platform.invokeMethod('startMonitoring');
    } catch (e) {
      print('启动原生监听器失败: $e');
    }

    // 初始化当前剪贴板状态（但不处理初始内容）
    await _initializeCurrentState();

    // 开始轮询
    _monitorTimer = Timer.periodic(checkInterval, (_) async {
      await _checkClipboard();
    });
  }

  /// 初始化当前剪贴板状态（启动时调用，不处理初始内容）
  Future<void> _initializeCurrentState() async {
    try {
      final result = await _platform.invokeMethod('getClipboardData');
      if (result != null) {
        final data = Map<String, dynamic>.from(result as Map);
        _currentData = data['content'] as String?;
        _currentChangeCount = data['changeCount'] as int?;
        print('✅ 剪贴板监听已初始化（不记录启动时的现有内容）');
      }
    } catch (e) {
      print('初始化剪贴板状态失败: $e');
    }
  }

  /// 启动自动捕获监听（增强版）
  ///
  /// 支持自定义捕获规则，包括去重窗口、内容长度限制等
  Future<void> startAuto({AutoCaptureRule? rule}) async {
    _captureRule = rule ?? const AutoCaptureRule();

    // 启动基础监听
    await start();

    print('✅ 自动监听已启动（去重窗口: ${_captureRule!.deduplicationWindow.inSeconds}秒）');
  }

  /// 停止监听
  Future<void> stop() async {
    if (!_isMonitoring) {
      return;
    }

    _isMonitoring = false;
    _statusController.add(false); // 发送状态更新
    _monitorTimer?.cancel();

    try {
      await _platform.invokeMethod('stopMonitoring');
    } catch (e) {
      print('停止原生监听器失败: $e');
    }
  }

  /// 检查剪贴板变化
  Future<void> _checkClipboard() async {
    try {
      // 检查是否是待处理的自己的复制操作（标志位检测）
      if (_isPendingOwnCopy) {
        _isPendingOwnCopy = false; // 清除标志
        print('⏭️  跳过自己的复制操作（标志位检测）');

        // 重要：获取并更新当前数据，避免下次轮询时重复记录
        final result = await _platform.invokeMethod('getClipboardData');
        if (result != null) {
          final data = Map<String, dynamic>.from(result as Map);
          _currentData = data['content'] as String?;
          _currentChangeCount = data['changeCount'] as int?;
        }

        return;
      }

      // 通过 Method Channel 获取当前剪贴板数据
      final result = await _platform.invokeMethod('getClipboardData');

      if (result == null) {
        return;
      }

      // 安全地转换 Map 类型
      final data = Map<String, dynamic>.from(result as Map);
      final content = data['content'] as String?;
      final changeCount = data['changeCount'] as int?;
      final sourceApp = data['sourceApp'] as String?;

      // 检查是否有变化
      if (changeCount != null && changeCount != _currentChangeCount) {
        _currentChangeCount = changeCount;

        if (content != null && content != _currentData) {
          // 检查是否应该忽略此内容
          if (sourceApp != null && shouldIgnoreApp(sourceApp)) {
            return;
          }

          _currentData = content;

          // 处理新的剪贴板内容
          await _processNewContent(content, sourceApp);
        }
      }
    } catch (e) {
      print('检查剪贴板失败: $e');
    }
  }

  /// 处理新的剪贴板内容
  Future<void> _processNewContent(
    String content,
    String? sourceApp,
  ) async {
    print('🔍 [DEBUG] _processNewContent 被调用，内容: "${content.substring(0, content.length > 20 ? 20 : content.length)}..."');
    _captureStopwatch..reset()..start();

    try {
      // 验证内容长度（如果设置了自动捕获规则）
      if (_captureRule != null && !_captureRule!.shouldCapture(content)) {
        print('⚠️  [DEBUG] 内容不符合捕获规则');
        if (content.isEmpty) {
          return; // 跳过空内容
        }
        if (content.length > _captureRule!.maxContentLength) {
          print('⚠️  内容过大（${content.length} 字符），已跳过');
          return;
        }
      }

      // 创建剪贴板项目
      final item = await _createClipboardItem(content, sourceApp);

      // 检查去重缓存
      if (_isDuplicateInCache(item.hash)) {
        return; // 跳过重复项
      }

      // 更新去重缓存
      _recentHashes[item.hash] = DateTime.now();

      // 清理过期缓存
      _cleanupExpiredHashes();

      // 加载当前历史
      final history = await storageService.load();

      // 检查是否重复（双重检查）
      if (history.items.any((existing) => existing.isDuplicate(item))) {
        return; // 跳过重复项
      }

      // 添加到历史
      final updated = history.add(item);

      // 批量保存优化
      await _saveHistoryIfNeeded(updated);

      final elapsed = _captureStopwatch.elapsedMilliseconds;
      if (elapsed > 100) {
        print('⚠️  [Performance] 捕获耗时 ${elapsed}ms');
      } else {
        print('📋 自动捕获: "${content.substring(0, content.length > 20 ? 20 : content.length)}..." (${elapsed}ms)');
      }
    } catch (e) {
      print('处理剪贴板内容失败: $e');
    } finally {
      _captureStopwatch.stop();
    }
  }

  /// 标记自己的复制操作
  void markOwnCopy(String content) {
    _isPendingOwnCopy = true; // 设置标志位
    print('📋 标记自己的复制操作（标志位已设置）: "${content.substring(0, content.length > 20 ? 20 : content.length)}..."');
  }

  /// 检查是否在去重缓存中
  bool _isDuplicateInCache(String hash) {
    final lastSeen = _recentHashes[hash];
    if (lastSeen == null) {
      return false;
    }

    // 检查是否在去重窗口内
    if (_captureRule != null) {
      final isDuplicate = DateTime.now().difference(lastSeen) < _captureRule!.deduplicationWindow;
      if (!isDuplicate) {
        // 窗口外，更新时间
        _recentHashes[hash] = DateTime.now();
      }
      return isDuplicate;
    }

    // 默认5秒窗口
    return DateTime.now().difference(lastSeen) < const Duration(seconds: 5);
  }

  /// 清理过期的去重缓存
  void _cleanupExpiredHashes() {
    final cutoff = DateTime.now().subtract(_captureRule?.deduplicationWindow ?? const Duration(seconds: 5));

    _recentHashes.removeWhere((hash, time) => time.isBefore(cutoff));
  }

  /// 立即保存历史记录
  ///
  /// 为了确保用户能立即看到复制的内容，改为每次捕获后都保存
  Future<void> _saveHistoryIfNeeded(models.ClipboardHistory history) async {
    // 获取保存前的记录数量（用于检测删除）
    final oldHistory = await storageService.load();
    final oldCount = oldHistory.items.length;

    // 保存新历史
    await storageService.save(history);

    // 检查是否有记录被删除
    final newCount = history.items.length;
    if (newCount < oldCount) {
      final deletedCount = oldCount - newCount;
      print('🗑️  为节省空间已删除 $deletedCount 条旧记录');
    }

    print('💾 历史已保存（${history.items.length} 条记录）');
  }

  /// 创建剪贴板项目
  Future<ClipboardItem> _createClipboardItem(
    String content,
    String? sourceApp,
  ) async {
    // 生成哈希
    final hash = _generateHash(content);

    // 检测内容类型
    final type = _detectContentType(content);

    // 自动分类
    final category = _classifyContent(content, type);

    // 调试：输出分类结果
    print('🏷️  [DEBUG] 内容分类: "$content" → ${category.name} (${type.name})');

    // 计算大小
    final size = utf8.encode(content).length;

    return ClipboardItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: type,
      categoryId: category.name,
      timestamp: DateTime.now(),
      hash: hash,
      size: size,
      sourceApp: sourceApp,
    );
  }

  /// 生成内容哈希（SHA-256 前 8 字符）
  String _generateHash(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// 检测内容类型
  ClipboardItemType _detectContentType(String content) {
    // 简单检测：如果内容很短且看起来像 URL，可能是 URL 类型
    if (content.startsWith('http://') || content.startsWith('https://')) {
      return ClipboardItemType.url;
    }

    return ClipboardItemType.text;
  }

  /// 分类内容（使用智能 CategoryDetector）
  Category _classifyContent(String content, ClipboardItemType type) {
    // 使用新的 CategoryDetector 进行智能分类
    // CategoryDetector 会自动识别：链接 > 文件 > 代码 > 文本
    return CategoryDetector.detect(content);
  }

  /// 检查是否应该忽略应用
  bool shouldIgnoreApp(String bundleId) {
    return _ignoredApps.any((ignored) => bundleId.contains(ignored));
  }

  /// 手动捕获项目（用于测试）
  Future<void> captureItem(ClipboardItem item) async {
    final history = await storageService.load();
    final updated = history.add(item);
    await storageService.save(updated);
  }

  /// 获取当前监听状态
  bool get isMonitoring => _isMonitoring;
}
