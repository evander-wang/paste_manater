import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/clipboard_history.dart';
import '../models/clipboard_item.dart';

/// 存储服务
///
/// 提供剪贴板历史的 JSON 持久化功能
class StorageService {
  /// 文件名
  static const String _filename = 'clipboard_history.json';

  /// 应用名称
  static const String _appName = 'paste_manager';

  /// 存储路径
  Future<String> get _storagePath async {
    final appSupportDir = await getApplicationSupportDirectory();
    final appDir = Directory('${appSupportDir.path}/$_appName');

    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }

    return '${appDir.path}/$_filename';
  }

  /// 加载剪贴板历史
  ///
  /// 如果文件不存在，返回空的历史记录
  Future<ClipboardHistory> load() async {
    try {
      final path = await _storagePath;
      final file = File(path);

      if (!await file.exists()) {
        return ClipboardHistory();
      }

      final json = await file.readAsString();
      final data = jsonDecode(json) as Map<String, dynamic>;

      return ClipboardHistory.fromJson(data);
    } catch (e) {
      // 如果加载失败，返回空历史
      return ClipboardHistory();
    }
  }

  /// 保存剪贴板历史
  Future<void> save(ClipboardHistory history) async {
    try {
      final path = await _storagePath;
      final file = File(path);

      final json = jsonEncode(history.toJson());
      await file.writeAsString(json);
    } catch (e) {
      // 如果保存失败，抛出异常
      throw StorageException('保存剪贴板历史失败: $e');
    }
  }

  /// 追加单个项目（优化性能）
  ///
  /// 直接追加到文件末尾，避免每次重写整个文件
  /// 定期需要压缩以移除已删除的项目
  Future<void> append(ClipboardItem item) async {
    // 简化实现：直接调用 save
    // TODO: 实现真正的增量追加
    final history = await load();
    final updated = history.add(item);
    await save(updated);
  }

  /// 清除所有历史
  Future<void> clear() async {
    try {
      final path = await _storagePath;
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw StorageException('清除剪贴板历史失败: $e');
    }
  }

  /// 获取存储文件大小
  Future<int> getStorageSize() async {
    try {
      final path = await _storagePath;
      final file = File(path);

      if (!await file.exists()) {
        return 0;
      }

      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  /// 置顶剪贴板历史项 (T054)
  ///
  /// 更新指定项目的置顶状态并保存
  Future<ClipboardHistory> pinItem(String itemId) async {
    final history = await load();
    final index = history.items.indexWhere((item) => item.id == itemId);

    if (index == -1) {
      throw ArgumentError('项目不存在: $itemId');
    }

    final item = history.items[index];
    final updated = item.copyWith(
      pinned: true,
      pinnedAt: DateTime.now(),
    );

    final updatedItems = List<ClipboardItem>.from(history.items);
    updatedItems[index] = updated;

    final updatedHistory = ClipboardHistory(
      initialItems: updatedItems,
      maxItems: history.maxItems,
      maxSize: history.maxSize,
    );
    await save(updatedHistory);

    return updatedHistory;
  }

  /// 取消置顶剪贴板历史项 (T055)
  ///
  /// 取消指定项目的置顶状态并保存
  Future<ClipboardHistory> unpinItem(String itemId) async {
    final history = await load();
    final index = history.items.indexWhere((item) => item.id == itemId);

    if (index == -1) {
      throw ArgumentError('项目不存在: $itemId');
    }

    final item = history.items[index];
    final updated = item.copyWith(
      pinned: false,
      clearPinnedAt: true, // 使用 clearPinnedAt 清除置顶时间
    );

    final updatedItems = List<ClipboardItem>.from(history.items);
    updatedItems[index] = updated;

    final updatedHistory = ClipboardHistory(
      initialItems: updatedItems,
      maxItems: history.maxItems,
      maxSize: history.maxSize,
    );
    await save(updatedHistory);

    return updatedHistory;
  }
}

/// 存储异常
class StorageException implements Exception {
  final String message;

  StorageException(this.message);

  @override
  String toString() => message;
}
