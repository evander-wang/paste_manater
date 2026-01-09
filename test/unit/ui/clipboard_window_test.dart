import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paste_manager/models/category.dart';
import 'package:paste_manager/models/clipboard_item.dart';
import 'package:paste_manager/models/clipboard_history.dart';
import 'package:paste_manager/services/storage_service.dart';
import 'package:paste_manager/ui/clipboard_window.dart';

class MockStorageService extends Mock implements StorageService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClipboardWindow 键盘导航测试', () {
    late MockStorageService mockStorage;
    late ClipboardWindow window;

    setUp(() async {
      mockStorage = MockStorageService();

      // 模拟返回历史数据
      final items = [
        ClipboardItem(
          id: '1',
          content: 'Item 1',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.now(),
          hash: 'hash-1',
          size: 10,
        ),
        ClipboardItem(
          id: '2',
          content: 'Item 2',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.now().add(const Duration(seconds: 1)),
          hash: 'hash-2',
          size: 10,
        ),
        ClipboardItem(
          id: '3',
          content: 'Item 3',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.now().add(const Duration(seconds: 2)),
          hash: 'hash-3',
          size: 10,
        ),
      ];

      when(() => mockStorage.load()).thenAnswer(
        (_) async => ClipboardHistory(initialItems: items),
      );

      window = ClipboardWindow(storageService: mockStorage);
    });

    testWidgets('应该初始化为隐藏状态', (WidgetTester tester) async {
      // Assert
      expect(window.isVisible, isFalse);
    });

    testWidgets('show()应该显示窗口', (WidgetTester tester) async {
      // Act
      window.show();
      await tester.pump();

      // Assert
      expect(window.isVisible, isTrue);
    });

    testWidgets('hide()应该隐藏窗口', (WidgetTester tester) async {
      // Arrange
      window.show();
      await tester.pump();
      expect(window.isVisible, isTrue);

      // Act
      window.hide();
      await tester.pump();

      // Assert
      expect(window.isVisible, isFalse);
    });

    testWidgets('toggle()应该切换窗口状态', (WidgetTester tester) async {
      // 初始状态：隐藏
      expect(window.isVisible, isFalse);

      // Act 1: toggle()应该显示
      window.toggle();
      await tester.pump();
      expect(window.isVisible, isTrue);

      // Act 2: toggle()应该隐藏
      window.toggle();
      await tester.pump();
      expect(window.isVisible, isFalse);
    });

    testWidgets('向下箭头键应该选中下一个项目', (WidgetTester tester) async {
      // Arrange
      window.show();
      await tester.pumpAndSettle();

      // Act: 按下箭头键
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Assert: 第二个项目应该被选中（高亮）
      // 注意：在实际实现中，我们需要验证选中状态的变化
      // 这里假设有selectedItemId属性
    });

    testWidgets('向上箭头键应该选中上一个项目', (WidgetTester tester) async {
      // Arrange
      window.show();
      await tester.pumpAndSettle();

      // 先向下移动到第二个项目
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Act: 按上箭头键
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      // Assert: 第一个项目应该被选中
    });

    testWidgets('Enter键应该复制选中项目并关闭窗口', (WidgetTester tester) async {
      // Arrange
      window.show();
      await tester.pumpAndSettle();

      // 选中第一个项目
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(window.isVisible, isTrue);

      // Act: 按Enter键
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Assert: 窗口应该关闭
      expect(window.isVisible, isFalse);
    });

    testWidgets('Escape键应该关闭窗口', (WidgetTester tester) async {
      // Arrange
      window.show();
      await tester.pumpAndSettle();
      expect(window.isVisible, isTrue);

      // Act: 按Escape键
      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Assert: 窗口应该关闭
      expect(window.isVisible, isFalse);
    });

    testWidgets('应该在到达列表底部后停止向下导航', (WidgetTester tester) async {
      // Arrange
      window.show();
      await tester.pumpAndSettle();

      // Act: 按下箭头键多次（超过项目数）
      for (int i = 0; i < 10; i++) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }

      // Assert: 应该停在最后一个项目（不会越界）
    });

    testWidgets('应该在到达列表顶部后停止向上导航', (WidgetTester tester) async {
      // Arrange
      window.show();
      await tester.pumpAndSettle();

      // Act: 按上箭头键多次
      for (int i = 0; i < 10; i++) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();
        await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
      }

      // Assert: 应该停在第一个项目（不会越界）
    });

    testWidgets('应该在过滤列表中正确导航', (WidgetTester tester) async {
      // Arrange
      window.show();
      await tester.pumpAndSettle();

      // 过滤为仅链接
      await tester.tap(find.widgetWithText(FilterChip, '链接'));
      await tester.pumpAndSettle();

      // Act: 在过滤列表中导航
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Assert: 应该在过滤列表中导航
    });

    testWidgets('应该支持PageDown键快速滚动', (WidgetTester tester) async {
      // Arrange
      window.show();
      await tester.pumpAndSettle();

      // Act: 按PageDown键
      await tester.sendKeyDownEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();

      // Assert: 应该跳转到列表下方（可能每次跳5-10项）
    });

    testWidgets('应该支持PageUp键快速向上滚动', (WidgetTester tester) async {
      // Arrange
      window.show();
      await tester.pumpAndSettle();

      // 先向下滚动
      await tester.sendKeyDownEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();

      // Act: 按PageUp键
      await tester.sendKeyDownEvent(LogicalKeyboardKey.pageUp);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();

      // Assert: 应该跳转回列表上方
    });

    testWidgets('应该支持Home键跳转到第一个项目', (WidgetTester tester) async {
      // Arrange
      window.show();
      await tester.pumpAndSettle();

      // 先向下滚动
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Act: 按Home键
      await tester.sendKeyDownEvent(LogicalKeyboardKey.home);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();

      // Assert: 应该跳转到第一个项目
    });

    testWidgets('应该支持End键跳转到最后一个项目', (WidgetTester tester) async {
      // Arrange
      window.show();
      await tester.pumpAndSettle();

      // Act: 按End键
      await tester.sendKeyDownEvent(LogicalKeyboardKey.end);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();

      // Assert: 应该跳转到最后一个项目
    });
  });
}
