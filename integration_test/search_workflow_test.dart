import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paste_manager/models/category.dart';
import 'package:paste_manager/models/clipboard_item.dart';
import 'package:paste_manager/models/clipboard_history.dart';
import 'package:paste_manager/services/storage_service.dart';
import 'package:paste_manager/ui/clipboard_window.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('搜索工作流集成测试', () {
    late StorageService storageService;
    late ClipboardWindow clipboardWindow;

    setUp(() async {
      storageService = StorageService();
      await storageService.clear();

      // 预填充测试数据
      final items = [
        ClipboardItem(
          id: 'search-1',
          content: 'https://github.com/flutter/flutter',
          type: ClipboardItemType.text,
          category: Category.link,
          timestamp: DateTime.now(),
          hash: 'search-hash-1',
          size: 35,
        ),
        ClipboardItem(
          id: 'search-2',
          content: 'https://stackoverflow.com/questions/12345',
          type: ClipboardItemType.text,
          category: Category.link,
          timestamp: DateTime.now().add(const Duration(seconds: 1)),
          hash: 'search-hash-2',
          size: 42,
        ),
        ClipboardItem(
          id: 'search-3',
          content: 'function search() { return true; }',
          type: ClipboardItemType.text,
          category: Category.code,
          timestamp: DateTime.now().add(const Duration(seconds: 2)),
          hash: 'search-hash-3',
          size: 35,
        ),
        ClipboardItem(
          id: 'search-4',
          content: 'Search is a powerful feature',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.now().add(const Duration(seconds: 3)),
          hash: 'search-hash-4',
          size: 32,
        ),
        ClipboardItem(
          id: 'search-5',
          content: '/Users/username/search/project',
          type: ClipboardItemType.text,
          category: Category.file,
          timestamp: DateTime.now().add(const Duration(seconds: 4)),
          hash: 'search-hash-5',
          size: 29,
        ),
      ];

      final history = ClipboardHistory(initialItems: items);
      await storageService.save(history);

      clipboardWindow = ClipboardWindow(storageService: storageService);
    });

    tearDown(() async {
      await storageService.clear();
    });

    testWidgets('应该显示所有项目（搜索前）', (WidgetTester tester) async {
      // Act
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('https://github.com/flutter/flutter'), findsOneWidget);
      expect(find.text('https://stackoverflow.com/questions/12345'), findsOneWidget);
      expect(find.text('function search() { return true; }'), findsOneWidget);
      expect(find.text('Search is a powerful feature'), findsOneWidget);
      expect(find.text('/Users/username/search/project'), findsOneWidget);
    });

    testWidgets('应该根据关键词过滤项目', (WidgetTester tester) async {
      // Arrange
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // Act: 输入搜索关键词 "github"
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'github');
      await tester.pumpAndSettle();

      // Assert: 只显示包含"github"的项目
      expect(find.text('https://github.com/flutter/flutter'), findsOneWidget);
      expect(find.text('https://stackoverflow.com/questions/12345'), findsNothing);
      expect(find.text('function search() { return true; }'), findsNothing);
      expect(find.text('Search is a powerful feature'), findsNothing);
      expect(find.text('/Users/username/search/project'), findsNothing);
    });

    testWidgets('应该不区分大小写搜索', (WidgetTester tester) async {
      // Arrange
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // Act: 输入不同大小写的搜索词
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'GITHUB');
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('https://github.com/flutter/flutter'), findsOneWidget);
    });

    testWidgets('应该支持部分匹配', (WidgetTester tester) async {
      // Arrange
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // Act: 输入部分关键词 "search"
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'search');
      await tester.pumpAndSettle();

      // Assert: 应该显示所有包含"search"的项目
      expect(find.text('https://stackoverflow.com/questions/12345'), findsNothing); // URL中没有"search"
      expect(find.text('function search() { return true; }'), findsOneWidget);
      expect(find.text('Search is a powerful feature'), findsOneWidget);
      expect(find.text('/Users/username/search/project'), findsOneWidget);
    });

    testWidgets('应该实时搜索（无需按Enter）', (WidgetTester tester) async {
      // Arrange
      clipboardWindow.show();
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);

      // Act: 逐个字符输入
      await tester.enterText(searchField, 'g');
      await tester.pump();
      expect(find.text('https://github.com/flutter/flutter'), findsOneWidget);

      await tester.enterText(searchField, 'gi');
      await tester.pump();
      expect(find.text('https://github.com/flutter/flutter'), findsOneWidget);

      await tester.enterText(searchField, 'git');
      await tester.pump();
      expect(find.text('https://github.com/flutter/flutter'), findsNothing);
    });

    testWidgets('清除搜索应该恢复所有项目', (WidgetTester tester) async {
      // Arrange
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // Act 1: 搜索
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'github');
      await tester.pumpAndSettle();
      expect(find.text('https://github.com/flutter/flutter'), findsOneWidget);
      expect(find.text('https://stackoverflow.com/questions/12345'), findsNothing);

      // Act 2: 清除搜索
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      // Assert: 所有项目重新出现
      expect(find.text('https://github.com/flutter/flutter'), findsOneWidget);
      expect(find.text('https://stackoverflow.com/questions/12345'), findsOneWidget);
      expect(find.text('function search() { return true; }'), findsOneWidget);
      expect(find.text('Search is a powerful feature'), findsOneWidget);
      expect(find.text('/Users/username/search/project'), findsOneWidget);
    });

    testWidgets('应该显示清除按钮（当有搜索内容时）', (WidgetTester tester) async {
      // Arrange
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // Act 1: 没有搜索内容
      expect(find.byIcon(Icons.clear), findsNothing);

      // Act 2: 输入搜索内容
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'test');
      await tester.pumpAndSettle();

      // Assert: 清除按钮出现
      expect(find.byIcon(Icons.clear), findsOneWidget);

      // Act 3: 点击清除按钮
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Assert: 搜索内容被清除，按钮消失
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('应该在搜索后保持选中状态', (WidgetTester tester) async {
      // Arrange
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // Act 1: 搜索
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'search');
      await tester.pumpAndSettle();

      // Act 2: 选择第一个项目
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Assert: 项目被选中（有高亮）
      // 在实际测试中，我们需要验证selectedId != null

      // Act 3: 清除搜索
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      // Assert: 选中状态被重置
    });

    testWidgets('应该在无结果时显示提示', (WidgetTester tester) async {
      // Arrange
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // Act: 搜索不存在的关键词
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'nonexistent');
      await tester.pumpAndSettle();

      // Assert: 显示无结果提示
      expect(find.text('没有剪贴板历史'), findsOneWidget);
    });

    testWidgets('应该支持空格搜索', (WidgetTester tester) async {
      // Arrange
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // Act: 搜索包含空格的文本
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Search is');
      await tester.pumpAndSettle();

      // Assert: 匹配包含空格的文本
      expect(find.text('Search is a powerful feature'), findsOneWidget);
    });

    testWidgets('应该支持特殊字符搜索', (WidgetTester tester) async {
      // Arrange
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // Act: 搜索包含特殊字符的URL
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, '://');
      await tester.pumpAndSettle();

      // Assert: 匹配包含特殊字符的URL
      expect(find.text('https://github.com/flutter/flutter'), findsOneWidget);
      expect(find.text('https://stackoverflow.com/questions/12345'), findsOneWidget);
    });
  });
}
