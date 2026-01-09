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

  group('删除项目工作流集成测试', () {
    late StorageService storageService;
    late ClipboardWindow clipboardWindow;

    setUp(() async {
      storageService = StorageService();
      await storageService.clear();

      // 预填充测试数据
      final items = [
        ClipboardItem(
          id: 'delete-1',
          content: 'Item to keep 1',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.now(),
          hash: 'delete-hash-1',
          size: 15,
        ),
        ClipboardItem(
          id: 'delete-2',
          content: 'Item to delete',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.now().add(const Duration(seconds: 1)),
          hash: 'delete-hash-2',
          size: 15,
        ),
        ClipboardItem(
          id: 'delete-3',
          content: 'Item to keep 2',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.now().add(const Duration(seconds: 2)),
          hash: 'delete-hash-3',
          size: 15,
        ),
      ];

      final history = ClipboardHistory(initialItems: items);
      await storageService.save(history);

      clipboardWindow = ClipboardWindow(storageService: storageService);
    });

    tearDown(() async {
      await storageService.clear();
    });

    testWidgets('应该删除单个项目', (WidgetTester tester) async {
      // Arrange
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // 验证初始状态
      expect(find.text('Item to keep 1'), findsOneWidget);
      expect(find.text('Item to delete'), findsOneWidget);
      expect(find.text('Item to keep 2'), findsOneWidget);

      // Act: 右键点击要删除的项目
      await tester.tap(find.text('Item to delete'), buttons: MouseButton.secondary);
      await tester.pumpAndSettle();

      // 点击"删除"菜单项（假设有上下文菜单）
      // 注意：当前实现可能没有上下文菜单，这是测试期望的行为

      // Assert: 验证项目已删除
      // expect(find.text('Item to delete'), findsNothing);
      // expect(find.text('Item to keep 1'), findsOneWidget);
      // expect(find.text('Item to keep 2'), findsOneWidget);
    });

    testWidgets('删除项目后应该持久化', (WidgetTester tester) async {
      // Arrange
      clipboardWindow.show();
      await tester.pumpAndSettle();

      final initialHistory = await storageService.load();
      expect(initialHistory.totalCount, 3);

      // Act: 删除一个项目（通过上下文菜单或按钮）
      // TODO: 实现删除功能后添加具体操作

      // 验证立即更新
      // expect(find.text('Item to delete'), findsNothing);

      // 关闭并重新打开窗口（模拟应用重启）
      clipboardWindow.hide();
      await tester.pumpAndSettle();

      // 重新加载
      final newWindow = ClipboardWindow(storageService: storageService);
      newWindow.show();
      await tester.pumpAndSettle();

      // Assert: 删除应该持久化
      // expect(find.text('Item to delete'), findsNothing);
    });

    testWidgets('应该支持"清除所有历史"操作', (WidgetTester tester) async {
      // Arrange
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // 验证初始状态
      expect(find.text('Item to keep 1'), findsOneWidget);
      expect(find.text('Item to delete'), findsOneWidget);
      expect(find.text('Item to keep 2'), findsOneWidget);

      // Act: 点击"清除所有历史"按钮
      // TODO: 添加清除按钮后实现具体操作
      // await tester.tap(find.text('清除所有历史'));
      // await tester.pumpAndSettle();

      // 显示确认对话框
      // expect(find.text('确认删除'), findsOneWidget);
      // expect(find.text('确定要清除所有剪贴板历史吗？'), findsOneWidget);

      // 点击确认
      // await tester.tap(find.text('删除'));
      // await tester.pumpAndSettle();

      // Assert: 所有项目应该被清除
      // expect(find.text('Item to keep 1'), findsNothing);
      // expect(find.text('Item to delete'), findsNothing);
      // expect(find.text('Item to keep 2'), findsNothing);
      // expect(find.text('没有剪贴板历史'), findsOneWidget);
    });

    testWidgets('清除历史应该持久化', (WidgetTester tester) async {
      // Arrange
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // Act: 清除所有历史
      // TODO: 实现清除功能
      // await tester.tap(find.text('清除所有历史'));
      // await tester.pumpAndSettle();
      // await tester.tap(find.text('删除'));
      // await tester.pumpAndSettle();

      // 关闭窗口
      clipboardWindow.hide();
      await tester.pumpAndSettle();

      // 重新加载
      final reloadedHistory = await storageService.load();

      // Assert: 历史应该仍然为空
      expect(reloadedHistory.totalCount, 0);
    });

    testWidgets('应该显示删除确认对话框', (WidgetTester tester) async {
      // Arrange
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // Act: 触发清除所有历史操作
      // TODO: 添加清除按钮
      // await tester.tap(find.text('清除所有历史'));
      // await tester.pumpAndSettle();

      // Assert: 应该显示确认对话框
      // expect(find.text('确认删除'), findsOneWidget);
      // expect(find.text('确定要清除所有剪贴板历史吗？'), findsOneWidget);
      // expect(find.text('取消'), findsOneWidget);
      // expect(find.text('删除'), findsOneWidget);
    });

    testWidgets('取消删除应该保留所有项目', (WidgetTester tester) async {
      // Arrange
      clipboardWindow.show();
      await tester.pumpAndSettle();

      final initialCount = (await storageService.load()).totalCount;

      // Act: 触发清除但取消
      // TODO: 实现清除功能
      // await tester.tap(find.text('清除所有历史'));
      // await tester.pumpAndSettle();
      // await tester.tap(find.text('取消'));
      // await tester.pumpAndSettle();

      // Assert: 所有项目应该保留
      // expect(find.text('Item to keep 1'), findsOneWidget);
      // expect(find.text('Item to delete'), findsOneWidget);

      final finalCount = (await storageService.load()).totalCount;
      expect(finalCount, equals(initialCount));
    });

    testWidgets('删除项目应该更新分类计数', (WidgetTester tester) async {
      // Arrange
      final itemsWithCategories = [
        ClipboardItem(
          id: 'text-1',
          content: 'Text item 1',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.now(),
          hash: 'text-1',
          size: 12,
        ),
        ClipboardItem(
          id: 'text-2',
          content: 'Text item 2',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.now().add(const Duration(seconds: 1)),
          hash: 'text-2',
          size: 12,
        ),
      ];

      await storageService.save(ClipboardHistory(initialItems: itemsWithCategories));
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // 验证初始计数（2个文本项）
      // expect(find.text('文本 2'), findsOneWidget);

      // Act: 删除一个文本项
      // TODO: 实现删除功能

      // Assert: 分类计数应该更新
      // expect(find.text('文本 1'), findsOneWidget);
    });

    testWidgets('应该支持批量删除（通过多选）', (WidgetTester tester) async {
      // Arrange
      clipboardWindow.show();
      await tester.pumpAndSettle();

      // Act: 选择多个项目
      // TODO: 实现多选功能
      // 长按第一个项目
      // 点击第二个项目

      // 执行批量删除
      // await tester.tap(find.text('删除选中项'));
      // await tester.pumpAndSettle();

      // Assert: 选中的项目应该被删除
    });

    testWidgets('删除最后一个项目应该显示空状态', (WidgetTester tester) async {
      // Arrange
      await storageService.save(
        ClipboardHistory(
          initialItems: [
            ClipboardItem(
              id: 'last-item',
              content: 'Only one item',
              type: ClipboardItemType.text,
              category: Category.text,
              timestamp: DateTime.now(),
              hash: 'last-hash',
              size: 13,
            ),
          ],
        ),
      );

      clipboardWindow.show();
      await tester.pumpAndSettle();

      // Act: 删除最后一个项目
      // TODO: 实现删除功能

      // Assert: 应该显示空状态提示
      // expect(find.text('没有剪贴板历史'), findsOneWidget);
    });
  });
}
