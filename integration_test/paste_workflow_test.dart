import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paste_manager/models/category.dart';
import 'package:paste_manager/models/clipboard_item.dart';
import 'package:paste_manager/models/clipboard_history.dart';
import 'package:paste_manager/services/storage_service.dart';
import 'package:paste_manager/ui/clipboard_window.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('从历史快速粘贴工作流集成测试', () {
    late StorageService storageService;
    late ClipboardWindow clipboardWindow;

    setUp(() async {
      storageService = StorageService();
      await storageService.clear();

      // 预填充一些测试数据
      final items = [
        ClipboardItem(
          id: 'test-1',
          content: 'First item',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.now(),
          hash: 'hash-1',
          size: 10,
        ),
        ClipboardItem(
          id: 'test-2',
          content: 'https://example.com',
          type: ClipboardItemType.text,
          category: Category.link,
          timestamp: DateTime.now().add(const Duration(seconds: 1)),
          hash: 'hash-2',
          size: 18,
        ),
        ClipboardItem(
          id: 'test-3',
          content: 'function test() { }',
          type: ClipboardItemType.text,
          category: Category.code,
          timestamp: DateTime.now().add(const Duration(seconds: 2)),
          hash: 'hash-3',
          size: 20,
        ),
      ];

      final history = ClipboardHistory(initialItems: items);
      await storageService.save(history);

      clipboardWindow = ClipboardWindow(storageService: storageService);
    });

    tearDown(() async {
      await storageService.clear();
    });

    testWidgets('应该显示所有历史项目', (WidgetTester tester) async {
      // Act
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('First item'), findsOneWidget);
      expect(find.text('https://example.com'), findsOneWidget);
      expect(find.text('function test() { }'), findsOneWidget);
    });

    testWidgets('应该能够点击选择项目', (WidgetTester tester) async {
      // Act
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // 点击第一个项目
      await tester.tap(find.text('First item'));
      await tester.pumpAndSettle();

      // Assert: 窗口应该关闭（项目被复制）
      expect(clipboardWindow.isVisible, isFalse);
    });

    testWidgets('应该支持键盘导航（向下键）', (WidgetTester tester) async {
      // Act
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // 模拟按下向下键
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Assert: 第二个项目应该被选中
      // 注意：这里假设选中状态有视觉反馈（如高亮）
      // 在实际测试中，我们需要验证选中状态的变化
    });

    testWidgets('应该支持键盘导航（向上键）', (WidgetTester tester) async {
      // Act
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // 先向下移动两次
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // 然后向上移动一次
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      // Assert: 第二个项目应该被选中
    });

    testWidgets('应该支持Enter键复制项目', (WidgetTester tester) async {
      // Act
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // 选择第一个项目
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // 记录当前窗口可见状态
      final wasVisible = clipboardWindow.isVisible;

      // 按Enter键
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Assert: 窗口应该关闭
      expect(wasVisible, isTrue);
      expect(clipboardWindow.isVisible, isFalse);
    });

    testWidgets('应该支持Escape键关闭窗口', (WidgetTester tester) async {
      // Act
      clipboardWindow.show();
      await tester.pumpAndSettle();

      expect(clipboardWindow.isVisible, isTrue);

      // 按Escape键
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Assert: 窗口应该关闭
      expect(clipboardWindow.isVisible, isFalse);
    });

    testWidgets('应该在复制项目后更新剪贴板', (WidgetTester tester) async {
      // Arrange
      const testContent = 'Test content for clipboard';

      final item = ClipboardItem(
        id: 'clipboard-test',
        content: testContent,
        type: ClipboardItemType.text,
        category: Category.text,
        timestamp: DateTime.now(),
        hash: 'clipboard-hash',
        size: testContent.length,
      );

      final history = await storageService.load();
      await storageService.save(history.add(item));

      // Act
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // 点击项目
      await tester.tap(find.text(testContent));
      await tester.pumpAndSettle();

      // Assert: 验证剪贴板内容
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      expect(clipboardData?.text, testContent);
    });

    testWidgets('应该支持快速连续选择多个项目', (WidgetTester tester) async {
      // Act
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // 选择第一个项目
      await tester.tap(find.text('First item'));
      await tester.pumpAndSettle();

      // 重新打开窗口
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // 选择第二个项目
      await tester.tap(find.text('https://example.com'));
      await tester.pumpAndSettle();

      // Assert: 第二个项目应该在剪贴板中
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      expect(clipboardData?.text, 'https://example.com');
    });

    testWidgets('应该在选择项目后保持焦点在窗口上', (WidgetTester tester) async {
      // Act
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // 点击项目
      await tester.tap(find.text('First item'));
      await tester.pumpAndSettle();

      // 重新打开窗口
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // Assert: 窗口应该仍然可见且有焦点
      expect(clipboardWindow.isVisible, isTrue);
    });

    testWidgets('应该在空历史中显示提示信息', (WidgetTester tester) async {
      // Arrange
      await storageService.clear();
      final emptyWindow = ClipboardWindow(storageService: storageService);

      // Act
      emptyWindow.show();
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('没有剪贴板历史'), findsOneWidget);
    });

    testWidgets('应该支持分类过滤后的项目选择', (WidgetTester tester) async {
      // Act
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // 点击"链接"分类过滤器
      await tester.tap(find.widgetWithText(FilterChip, '链接'));
      await tester.pumpAndSettle();

      // 选择链接项目
      await tester.tap(find.text('https://example.com'));
      await tester.pumpAndSettle();

      // Assert: 窗口应该关闭
      expect(clipboardWindow.isVisible, isFalse);
    });
  });
}
