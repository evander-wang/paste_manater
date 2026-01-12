import 'dart:async';
import 'dart:io';

/// 文件变化事件封装
class FileChangeEvent {
  final String path;
  final FileChangeType type;

  FileChangeEvent(this.path, this.type);

  factory FileChangeEvent.modify(String path) {
    return FileChangeEvent(path, FileChangeType.modify);
  }
}

/// 文件变化类型
enum FileChangeType {
  modify,
  create,
  delete,
}

/// 文件监听服务
///
/// 监听指定文件的变化事件(修改、创建、删除)
/// 实现500ms防抖,失败时降级为10秒轮询
class FileWatcherService {
  Timer? _debounceTimer;
  Timer? _pollingTimer;
  StreamSubscription<FileSystemEvent>? _watcherSubscription;
  static const _debounceDuration = Duration(milliseconds: 500);
  static const _pollingInterval = Duration(seconds: 10);

  DateTime? _lastCheckTime;

  /// 文件变化回调
  void Function(FileChangeEvent)? _onChange;

  FileWatcherService();

  /// 开始监听文件变化
  ///
  /// [filePath] 要监听的文件路径
  /// [onChange] 文件变化回调函数
  ///
  /// 返回可取消的StreamSubscription
  StreamSubscription<FileSystemEvent> watch(
    String filePath,
    void Function(FileChangeEvent) onChange,
  ) {
    _onChange = onChange;

    try {
      // 尝试使用FileSystemWatcher
      final file = File(filePath);
      _watcherSubscription = file.watch().listen(
        (event) {
          if (event.type == FileSystemEvent.modify ||
              event.type == FileSystemEvent.create) {
            _handleFileChange(FileChangeEvent(filePath, FileChangeType.modify));
          }
        },
        onError: (error) {
          // 监听失败,降级到轮询模式
          _fallbackToPolling(filePath);
        },
      );
      return _watcherSubscription!;
    } catch (e) {
      // 创建监听器失败,直接降级到轮询
      _fallbackToPolling(filePath);
      // 创建一个假的stream subscription
      final controller = StreamController<FileSystemEvent>();
      controller.close();
      return controller.stream.listen((_) {});
    }
  }

  /// 处理文件变化事件(带防抖)
  void _handleFileChange(FileChangeEvent event) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _onChange?.call(event);
    });
  }

  /// 降级到轮询模式
  void _fallbackToPolling(String filePath) {
    _watcherSubscription?.cancel();
    _lastCheckTime = DateTime.now();

    _pollingTimer = Timer.periodic(_pollingInterval, (timer) {
      final file = File(filePath);
      if (!file.existsSync()) {
        return; // 文件不存在,跳过
      }

      try {
        final lastModified = file.lastModifiedSync();
        if (_lastCheckTime != null && lastModified.isAfter(_lastCheckTime!)) {
          _lastCheckTime = lastModified;
          // 模拟文件修改事件
          _onChange?.call(FileChangeEvent.modify(filePath));
        }
        _lastCheckTime = lastModified;
      } catch (e) {
        // 忽略错误
      }
    });
  }

  /// 停止监听
  ///
  /// [subscription] watch()返回的订阅对象
  void cancel(StreamSubscription subscription) {
    _debounceTimer?.cancel();
    _pollingTimer?.cancel();
    subscription.cancel();
  }

  /// 释放资源
  void dispose() {
    _debounceTimer?.cancel();
    _pollingTimer?.cancel();
    _watcherSubscription?.cancel();
  }
}
