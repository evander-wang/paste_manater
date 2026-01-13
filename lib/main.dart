import 'dart:async';
import 'package:flutter/material.dart';
import 'services/storage_service.dart';
import 'services/clipboard_monitor.dart';
import 'services/hotkey_manager.dart';
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

class _PasteManagerAppState extends State<PasteManagerApp> {
  late ClipboardHistoryController _historyController;

  @override
  void initState() {
    super.initState();

    // 初始化控制器
    _historyController = ClipboardHistoryController(
      storageService: widget.storageService,
      clipboardMonitor: widget.clipboardMonitor,
    );

    // 初始化应用
    _initializeApp();
  }

  @override
  void dispose() {
    _historyController.dispose();
    super.dispose();
  }

  /// 初始化应用
  Future<void> _initializeApp() async {
    await _historyController.initialize();
    await _startAutoMonitoring();
    await _registerHotkey();
  }

  /// 自动启动监听
  Future<void> _startAutoMonitoring() async {
    try {
      await widget.clipboardMonitor.startAuto();
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
        body: ClipboardHistoryTab(
          controller: _historyController,
          clipboardMonitor: widget.clipboardMonitor,
          storageService: widget.storageService,
        ),
      ),
    );
  }
}
