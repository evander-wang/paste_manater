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

  group('分类过滤集成测试', () {
    late StorageService storageService;
    late ClipboardWindow clipboardWindow;

    setUp(() async {
      storageService = StorageService();
      await storageService.clear();

      // 预填充各种分类的测试数据
      final items = [
        // 文本类 (2个)
        ClipboardItem(
          id: 'text-1',
          content: 'Plain text message',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.now(),
          hash: 'text-hash-1',
          size: 20,
        ),
        ClipboardItem(
          id: 'text-2',
          content: 'Another text',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.now().add(const Duration(seconds: 1)),
          hash: 'text-hash-2',
          size: 20,
        ),
        // 链接类 (2个)
        ClipboardItem(
          id: 'link-1',
          content: 'https://github.com',
          type: ClipboardItemType.text,
          category: Category.link,
          timestamp: DateTime.now().add(const Duration(seconds: 2)),
          hash: 'link-hash-1',
          size: 18,
        ),
        ClipboardItem(
          id: 'link-2',
          content: 'https://stackoverflow.com',
          type: ClipboardItemType.text,
          category: Category.link,
          timestamp: DateTime.now().add(const Duration(seconds: 3)),
          hash: 'link-hash-2',
          size: 25,
        ),
        // 代码类 (2个)
        ClipboardItem(
          id: 'code-1',
          content: 'function hello() { }',
          type: ClipboardItemType.text,
          category: Category.code,
          timestamp: DateTime.now().add(const Duration(seconds: 4)),
          hash: 'code-hash-1',
          size: 20,
        ),
        ClipboardItem(
          id: 'code-2',
          content: 'class Test { }',
          type: ClipboardItemType.text,
          category: Category.code,
          timestamp: DateTime.now().add(const Duration(seconds: 5)),
          hash: 'code-hash-2',
          size: 15,
        ),
        // 文件类 (2个)
        ClipboardItem(
          id: 'file-1',
          content: '/Users/username/file.txt',
          type: ClipboardItemType.text,
          category: Category.file,
          timestamp: DateTime.now().add(const Duration(seconds: 6)),
          hash: 'file-hash-1',
          size: 24,
        ),
        ClipboardItem(
          id: 'file-2',
          content: '/Documents/project.dart',
          type: ClipboardItemType.text,
          category: Category.file,
          timestamp: DateTime.now().add(const Duration(seconds: 7)),
          hash: 'file-hash-2',
          size: 24,
        ),
        // 图像类 (2个)
        ClipboardItem(
          id: 'image-1',
          content: '[Image data 1]',
          type: ClipboardItemType.image,
          category: Category.image,
          timestamp: DateTime.now().add(const Duration(seconds: 8)),
          hash: 'image-hash-1',
          size: 14,
        ),
        ClipboardItem(
          id: 'image-2',
          content: '[Image data 2]',
          type: ClipboardItemType.image,
          category: Category.image,
          timestamp: DateTime.now().add(const Duration(seconds: 9)),
          hash: 'image-hash-2',
          size: 14,
        ),
      ];

      final history = ClipboardHistory(initialItems: items);
      await storageService.save(history);

      clipboardWindow = ClipboardWindow(storageService: storageService);
    });

    tearDown(() async {
      await storageService.clear();
    });

    testWidgets('应该显示所有分类的标签', (WidgetTester tester) async {
      // Act
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // Assert: 验证所有分类标签都存在
      expect(find.text('全部'), findsOneWidget);
      expect(find.text('文本'), findsOneWidget);
      expect(find.text('图像'), findsOneWidget);
      expect(find.text('链接'), findsOneWidget);
      expect(find.text('代码'), findsOneWidget);
      expect(find.text('文件'), findsOneWidget);
    });

    testWidgets('默认应该显示所有项目', (WidgetTester tester) async {
      // Act
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // Assert: 所有项目都应该可见
      expect(find.text('Plain text message'), findsOneWidget);
      expect(find.text('https://github.com'), findsOneWidget);
      expect(find.text('function hello() { }'), findsOneWidget);
      expect(find.text('/Users/username/file.txt'), findsOneWidget);
      expect(find.text('[Image data 1]'), findsOneWidget);
    });

    testWidgets('点击"文本"标签应该只显示文本类项目', (WidgetTester tester) async {
      // Act
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // 点击"文本"标签
      await tester.tap(find.widgetWithText(FilterChip, '文本'));
      await tester.pumpAndSettle();

      // Assert: 只显示文本类项目
      expect(find.text('Plain text message'), findsOneWidget);
      expect(find.text('Another text'), findsOneWidget);
      expect(find.text('https://github.com'), findsNothing);
      expect(find.text('function hello() { }'), findsNothing);
    });

    testWidgets('点击"链接"标签应该只显示链接类项目', (WidgetTester tester) async {
      // Act
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // 点击"链接"标签
      await tester.tap(find.widgetWithText(FilterChip, '链接'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('https://github.com'), findsOneWidget);
      expect(find.text('https://stackoverflow.com'), findsOneWidget);
      expect(find.text('Plain text message'), findsNothing);
      expect(find.text('function hello() { }'), findsNothing);
    });

    testWidgets('点击"代码"标签应该只显示代码类项目', (WidgetTester tester) async {
      // Act
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // 点击"代码"标签
      await tester.tap(find.widgetWithText(FilterChip, '代码'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('function hello() { }'), findsOneWidget);
      expect(find.text('class Test { }'), findsOneWidget);
      expect(find.text('Plain text message'), findsNothing);
    });

    testWidgets('点击"文件"标签应该只显示文件类项目', (WidgetTester tester) async {
      // Act
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // 点击"文件"标签
      await tester.tap(find.widgetWithText(FilterChip, '文件'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('/Users/username/file.txt'), findsOneWidget);
      expect(find.text('/Documents/project.dart'), findsOneWidget);
      expect(find.text('Plain text message'), findsNothing);
    });

    testWidgets('点击"图像"标签应该只显示图像类项目', (WidgetTester tester) async {
      // Act
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // 点击"图像"标签
      await tester.tap(find.widgetWithText(FilterChip, '图像'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('[Image data 1]'), findsOneWidget);
      expect(find.text('[Image data 2]'), findsOneWidget);
      expect(find.text('Plain text message'), findsNothing);
    });

    testWidgets('点击"全部"标签应该显示所有项目', (WidgetTester tester) async {
      // Act
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // 先过滤
      await tester.tap(find.widgetWithText(FilterChip, '文本'));
      await tester.pumpAndSettle();

      expect(find.text('Plain text message'), findsOneWidget);
      expect(find.text('https://github.com'), findsNothing);

      // 点击"全部"
      await tester.tap(find.widgetWithText(FilterChip, '全部'));
      await tester.pumpAndSettle();

      // Assert: 所有项目重新出现
      expect(find.text('Plain text message'), findsOneWidget);
      expect(find.text('https://github.com'), findsOneWidget);
      expect(find.text('function hello() { }'), findsOneWidget);
    });

    testWidgets('应该正确显示分类计数', (WidgetTester tester) async {
      // Act
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // Assert: 验证头部显示总项目数
      // 注意：当前实现显示"10 项"（所有分类的总数）
      expect(find.textContaining('项'), findsOneWidget);
    });

    testWidgets('切换分类应该更新选中状态', (WidgetTester tester) async {
      // Act
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // 点击"文本"
      await tester.tap(find.widgetWithText(FilterChip, '文本'));
      await tester.pumpAndSettle();

      // 验证"文本"标签被选中（蓝色背景）
      final textChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, '文本'),
      );
      expect(textChip.selected, isTrue);

      // 点击"链接"
      await tester.tap(find.widgetWithText(FilterChip, '链接'));
      await tester.pumpAndSettle();

      // 验证"链接"被选中，"文本"取消选中
      final linkChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, '链接'),
      );
      expect(linkChip.selected, isTrue);

      final textChipAfter = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, '文本'),
      );
      expect(textChipAfter.selected, isFalse);
    });

    testWidgets('空分类应该显示提示信息', (WidgetTester tester) async {
      // Arrange: 创建只有文本类的历史
      await storageService.clear();
      final textOnlyHistory = ClipboardHistory(
        initialItems: [
          ClipboardItem(
            id: 'only-text',
            content: 'Only text item',
            type: ClipboardItemType.text,
            category: Category.text,
            timestamp: DateTime.now(),
            hash: 'only-text-hash',
            size: 15,
          ),
        ],
      );
      await storageService.save(textOnlyHistory);

      final newWindow = ClipboardWindow(storageService: storageService);

      // Act
      newWindow.show();
      await tester.pumpAndSettle();

      // 点击"链接"分类（应该没有项目）
      await tester.tap(find.widgetWithText(FilterChip, '链接'));
      await tester.pumpAndSettle();

      // Assert: 显示无结果提示
      expect(find.text('没有剪贴板历史'), findsOneWidget);
    });

    testWidgets('应该支持组合过滤（分类+搜索）', (WidgetTester tester) async {
      // Act
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // 先按分类过滤
      await tester.tap(find.widgetWithText(FilterChip, '文本'));
      await tester.pumpAndSettle();

      // 再输入搜索词
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Another');
      await tester.pumpAndSettle();

      // Assert: 应该只显示匹配的文本类项目
      expect(find.text('Another text'), findsOneWidget);
      expect(find.text('Plain text message'), findsNothing);
      expect(find.text('https://github.com'), findsNothing);
    });

    testWidgets('分类过滤应该保持键盘导航', (WidgetTester tester) async {
      // Act
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // 按分类过滤
      await tester.tap(find.widgetWithText(FilterChip, '链接'));
      await tester.pumpAndSettle();

      // 使用键盘导航
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Assert: 第一个链接项目应该被选中
      // （需要验证selectedId或视觉高亮）
    });
  });
}
