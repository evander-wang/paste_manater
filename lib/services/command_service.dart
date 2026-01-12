import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:paste_manager/models/command.dart';
import 'package:paste_manager/services/fileWatcher_service.dart';
import 'package:path_provider/path_provider.dart';

/// CommandService - 常用命令管理服务
///
/// 负责:
/// - 从文件加载命令列表
/// - 保存命令列表到文件
/// - 监听文件变化并自动重载
/// - 复制命令到剪贴板
/// - 命令置顶/取消置顶
class CommandService {
  FileWatcherService? _fileWatcher;
  StreamSubscription<dynamic>? _watcherSubscription;
  final _commandController = StreamController<List<Command>>.broadcast();

  /// 获取命令变化流
  Stream<List<Command>> get commandStream => _commandController.stream;

  /// 当前加载的命令列表
  List<Command> _currentCommands = [];

  /// 获取当前命令列表
  List<Command> get currentCommands => List.unmodifiable(_currentCommands);

  /// 初始化服务
  ///
  /// 加载命令文件并启动文件监听
  Future<void> initialize() async {
    // 使用应用支持目录,无需额外权限
    final appSupportDir = await getApplicationSupportDirectory();
    final commandFile = File('${appSupportDir.path}/.paste_manager.json');

    // 如果用户主目录有配置文件,复制到应用目录
    final userHomeFile = File('${Platform.environment['HOME']}/.paste_manager.json');
    if (await userHomeFile.exists() && !await commandFile.exists()) {
      try {
        await userHomeFile.copy(commandFile.path);
      } catch (e) {
        // 忽略复制错误,使用空配置
      }
    }

    // 加载命令
    _currentCommands = await loadCommands(commandFile.path);

    // 启动文件监听
    _startWatching(commandFile.path);
  }

  /// 从指定路径加载命令列表
  ///
  /// 返回按置顶状态排序的命令列表
  Future<List<Command>> loadCommands(String filePath) async {
    final file = File(filePath);

    // 文件不存在时返回空列表
    if (!await file.exists()) {
      return [];
    }

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      if (!json.containsKey('commands')) {
        return [];
      }

      final commandsJson = json['commands'] as List;
      final commands = commandsJson
          .map((json) => Command.fromJson(json as Map<String, dynamic>))
          .toList();

      // 按置顶状态和置顶时间排序
      return _sortByPinStatus(commands);
    } on FormatException catch (e) {
      throw FormatException('JSON格式错误: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// 保存命令列表到指定路径
  ///
  /// 使用原子写入确保数据完整性
  Future<void> saveCommands(String filePath, List<Command> commands) async {
    final file = File(filePath);
    final tempFile = File('$filePath.tmp');

    try {
      // 构建JSON数据
      final data = {
        'version': '1.0',
        'commands': commands.map((cmd) => cmd.toJson()).toList(),
      };

      // 先写入临时文件
      await tempFile.writeAsString(jsonEncode(data));

      // 原子性重命名
      await tempFile.rename(filePath);

      // 更新当前命令列表
      _currentCommands = _sortByPinStatus(commands);

      // 通知监听器
      _commandController.add(_currentCommands);
    } catch (e) {
      // 清理临时文件
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }

  /// 复制命令到剪贴板
  ///
  /// 复制命令到剪贴板
  Future<void> copyToClipboard(Command command) async {
    print('📋 开始复制命令: ${command.name} -> ${command.command}');
    await Clipboard.setData(ClipboardData(text: command.command));
    print('✅ 命令已复制到剪贴板');
  }

  /// 置顶命令
  Future<void> pinCommand(String commandId) async {
    final index = _currentCommands.indexWhere((cmd) => cmd.id == commandId);
    if (index == -1) {
      throw ArgumentError('命令不存在: $commandId');
    }

    final command = _currentCommands[index];
    final updated = command.copyWith(
      pinned: true,
      pinnedAt: DateTime.now(),
    );

    _currentCommands[index] = updated;
    _currentCommands = _sortByPinStatus(_currentCommands);

    _commandController.add(_currentCommands);
  }

  /// 取消置顶命令
  Future<void> unpinCommand(String commandId) async {
    final index = _currentCommands.indexWhere((cmd) => cmd.id == commandId);
    if (index == -1) {
      throw ArgumentError('命令不存在: $commandId');
    }

    final command = _currentCommands[index];
    final updated = command.copyWith(
      pinned: false,
      clearPinnedAt: true, // 使用 clearPinnedAt 清除置顶时间
    );

    _currentCommands[index] = updated;
    _currentCommands = _sortByPinStatus(_currentCommands);

    _commandController.add(_currentCommands);
  }

  /// 按置顶状态排序
  ///
  /// 置顶的项目在前,按置顶时间倒序
  /// 未置顶的项目在后
  List<Command> _sortByPinStatus(List<Command> commands) {
    final pinned = commands.where((cmd) => cmd.pinned).toList()
      ..sort((a, b) {
        final aTime = a.pinnedAt ?? DateTime(0);
        final bTime = b.pinnedAt ?? DateTime(0);
        return bTime.compareTo(aTime); // 倒序
      });

    final unpinned = commands.where((cmd) => !cmd.pinned).toList();

    return [...pinned, ...unpinned];
  }

  /// 启动文件监听
  void _startWatching(String filePath) {
    _fileWatcher = FileWatcherService();

    _watcherSubscription = _fileWatcher!.watch(
      filePath,
      (event) async {
        // 文件变化时重新加载
        try {
          _currentCommands = await loadCommands(filePath);
          _commandController.add(_currentCommands);
        } catch (e) {
          // 错误处理:可以发送错误事件
        }
      },
    );
  }

  /// 释放资源
  void dispose() {
    _watcherSubscription?.cancel();
    _fileWatcher?.dispose();
    _commandController.close();
  }
}
