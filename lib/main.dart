import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/clipboard_history.dart';
import 'services/storage_service.dart';
import 'services/clipboard_monitor.dart';
import 'services/hotkey_manager.dart';
import 'widgets/monitoring_status_widget.dart';
import 'widgets/command_tab.dart';
import 'controllers/clipboard_history_controller.dart';
import 'ui/clipboard_history_tab.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化服务
  final storageService = StorageService();
  final clipboardMonitor = ClipboardMonitor(
    storageService: storageService,
  );

  // 初始化热键管理器
  final hotkeyManager = HotkeyManager(
    storageService: storageService,
  );

  runApp(PasteManagerApp(
    clipboardMonitor: clipboardMonitor,
    hotkeyManager: hotkeyManager,
    storageService: storageService,
  ));
}

class PasteManagerApp extends StatefulWidget {
  final ClipboardMonitor clipboardMonitor;
  final HotkeyManager hotkeyManager;
  final StorageService storageService;

  const PasteManagerApp({
    super.key,
    required this.clipboardMonitor,
    required this.hotkeyManager,
    required this.storageService,
  });

  @override
  State<PasteManagerApp> createState() => _PasteManagerAppState();
}

class _PasteManagerAppState extends State<PasteManagerApp>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ClipboardHistoryController _historyController;
  bool _isMonitoring = false;
  StreamSubscription<bool>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    // 初始化 TabController (2个标签页)
    _tabController = TabController(length: 2, vsync: this);

    // 初始化控制器
    _historyController = ClipboardHistoryController(
      storageService: widget.storageService,
      clipboardMonitor: widget.clipboardMonitor,
    );

    // 初始化控制器和监听
    _initializeApp();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _statusSubscription?.cancel();
    _historyController.dispose();
    super.dispose();
  }

  /// 初始化应用
  Future<void> _initializeApp() async {
    await _historyController.initialize();
    await _startAutoMonitoring();
    _listenToStatusChanges();
    await _registerHotkey();
  }

  /// 监听监听状态变化
  void _listenToStatusChanges() {
    _statusSubscription = widget.clipboardMonitor.statusStream.listen((isMonitoring) {
      if (mounted) {
        setState(() {
          _isMonitoring = isMonitoring;
        });
      }
    });
  }

  /// 自动启动监听
  Future<void> _startAutoMonitoring() async {
    try {
      await widget.clipboardMonitor.startAuto();
      setState(() {
        _isMonitoring = true;
      });
      print('✅ 应用启动时自动开启剪贴板监听');
    } catch (e) {
      debugPrint('自动启动监听失败: $e');
    }
  }

  /// 自动注册热键
  Future<void> _registerHotkey() async {
    try {
      await widget.hotkeyManager.register(
        HotkeyManager.defaultHotkey,
        () {
          debugPrint('热键触发：Cmd+Shift+V');
        },
      );
      print('✅ 热键已自动注册：Cmd+Shift+V（显示/隐藏窗口）');
    } catch (e) {
      debugPrint('热键注册失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '智能剪贴板管理器',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('智能剪贴板管理器'),
          actions: [
            // 状态显示组件
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: MonitoringStatusWidget(
                  isMonitoring: _isMonitoring,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _historyController.loadHistory,
              tooltip: '刷新历史',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '剪贴板历史', icon: Icon(Icons.history)),
              Tab(text: '常用命令', icon: Icon(Icons.terminal)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // 第一个标签页: 剪贴板历史
            ClipboardHistoryTab(
              controller: _historyController,
              clipboardMonitor: widget.clipboardMonitor,
              storageService: widget.storageService,
            ),
            // 第二个标签页: 常用命令
            CommandTab(clipboardMonitor: widget.clipboardMonitor),
          ],
        ),
      ),
    );
  }
}
