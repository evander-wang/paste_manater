import 'package:flutter/material.dart';
import 'package:paste_manager/models/command.dart';
import 'package:paste_manager/services/command_service.dart';
import 'package:paste_manager/services/clipboard_monitor.dart';
import 'package:paste_manager/widgets/command_list_item.dart';
import 'package:paste_manager/ui/empty_state_view.dart';
import 'dart:async';

/// CommandTab - 常用命令标签页
///
/// 显示命令列表,支持点击复制、空状态提示、错误提示
class CommandTab extends StatefulWidget {
  final ClipboardMonitor? clipboardMonitor;

  const CommandTab({super.key, this.clipboardMonitor});

  @override
  State<CommandTab> createState() => _CommandTabState();
}

class _CommandTabState extends State<CommandTab> {
  final CommandService _commandService = CommandService();
  List<Command> _commands = [];
  String? _errorMessage;
  bool _isLoading = true;
  StreamSubscription<List<Command>>? _subscription;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _commandService.initialize();
      print('📀 CommandTab: 初始化成功,加载了 ${_commandService.currentCommands.length} 个命令');
      setState(() {
        _commands = _commandService.currentCommands;
        _isLoading = false;
      });

      // 监听命令变化
      _subscription = _commandService.commandStream.listen((commands) {
        print('📀 CommandTab: 收到命令更新,数量: ${commands.length}');
        if (mounted) {
          setState(() {
            _commands = commands;
          });
        }
      });
    } catch (e) {
      print('❌ CommandTab: 初始化失败 - $e');
      setState(() {
        _errorMessage = '加载命令失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _commandService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (_commands.isEmpty) {
      return _buildEmptyView();
    }

    return _buildCommandList();
  }

  /// 构建命令列表
  Widget _buildCommandList() {
    return ListView.builder(
      itemCount: _commands.length,
      itemBuilder: (context, index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: CommandListItem(
            key: ValueKey(_commands[index].id),
            command: _commands[index],
            onTap: () => _copyCommand(_commands[index]),
            commandService: _commandService,
          ),
        );
      },
    );
  }

  /// 构建空状态视图
  Widget _buildEmptyView() {
    return EmptyStateView(
      icon: Icons.folder_open,
      title: '暂无常用命令',
      subtitles: [
        '请在应用支持目录中创建 .paste_manager.json 文件',
        '或在 ~/.paste_manager.json 创建后重启应用',
      ],
      exampleCode: '''{
  "version": "1.0",
  "commands": [
    {
      "id": "1",
      "name": "启动服务",
      "command": "npm start",
      "createdAt": "2026-01-12T10:00:00.000Z",
      "modifiedAt": "2026-01-12T10:00:00.000Z",
      "pinned": false
    }
  ]
}''',
    );
  }

  /// 构建错误视图
  Widget _buildErrorView() {
    final errorHints = <String>[
      _errorMessage ?? '未知错误',
    ];

    if (_errorMessage?.contains('JSON') == true) {
      errorHints.add('请检查 ~/.paste_manager.json 文件格式是否正确');
    }

    return EmptyStateView(
      icon: Icons.error_outline,
      title: '加载失败',
      subtitles: errorHints,
      iconColor: Colors.red[400],
    );
  }

  /// 复制命令到剪贴板
  Future<void> _copyCommand(Command command) async {
    print('🖱️ CommandTab: 点击了命令 - ${command.name}');
    try {
      // 标记为自己的复制操作，避免被 ClipboardMonitor 重新记录
      widget.clipboardMonitor?.markOwnCopy(command.command);

      await _commandService.copyToClipboard(command);

      if (!mounted) return;

      print('✅ CommandTab: 准备显示 SnackBar');
      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已复制: ${command.name}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: '确定',
            onPressed: () {},
          ),
        ),
      );
      print('✅ CommandTab: SnackBar 已显示');
    } catch (e) {
      if (!mounted) return;

      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('复制失败: $e'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
