import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/models/category_base.dart';
import 'package:paste_manager/ui/delete_category_dialog.dart';

class MockCategory extends CategoryBase {
  @override
  String get id => 'test_category';

  @override
  String get displayName => '测试分类';

  @override
  IconData get icon => Icons.folder;

  @override
  Color get color => Colors.blue;

  @override
  bool get isPreset => false;
}

void main() {
  group('T040: DeleteCategoryDialog Widget测试', () {
    group('确认流程', () {
      testWidgets('应该显示分类名称和项目数量', (WidgetTester tester) async {
        // Arrange
        final category = MockCategory();
        const itemCount = 5;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DeleteCategoryDialog(
                category: category,
                itemCount: itemCount,
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('删除分类'), findsOneWidget);
        expect(find.text('分类"${category.displayName}"下还有 $itemCount 个项目。'), findsOneWidget);
        expect(find.text('请先清空或移动这些项目后再删除分类。'), findsOneWidget);
      });

      testWidgets('应该显示确认和取消按钮', (WidgetTester tester) async {
        // Arrange
        final category = MockCategory();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DeleteCategoryDialog(
                category: category,
                itemCount: 0,
              ),
            ),
          ),
        );

        // Assert - 查找按钮
        expect(find.text('取消'), findsOneWidget);
        expect(find.text('删除'), findsOneWidget);
      });

      testWidgets('点击确认按钮应该返回true', (WidgetTester tester) async {
        // Arrange
        final category = MockCategory();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DeleteCategoryDialog(
                category: category,
                itemCount: 0,
              ),
            ),
          ),
        );

        // Act - 点击确认按钮
        await tester.tap(find.text('删除'));
        await tester.pumpAndSettle();

        // Assert - 对话框关闭（通过 Navigator.pop(true)）
        expect(find.byType(DeleteCategoryDialog), findsNothing);
      });

      testWidgets('点击取消按钮应该返回false', (WidgetTester tester) async {
        // Arrange
        final category = MockCategory();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DeleteCategoryDialog(
                category: category,
                itemCount: 0,
              ),
            ),
          ),
        );

        // Act - 点击取消按钮
        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();

        // Assert - 对话框应该关闭
        expect(find.byType(DeleteCategoryDialog), findsNothing);
      });
    });

    group('空分类提示', () {
      testWidgets('空分类应该显示不同的提示信息', (WidgetTester tester) async {
        // Arrange
        final category = MockCategory();
        const itemCount = 0;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DeleteCategoryDialog(
                category: category,
                itemCount: itemCount,
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('确认删除分类"${category.displayName}"吗?'), findsOneWidget);
        expect(find.text('删除后无法恢复。'), findsOneWidget);
      });
    });

    group('非空分类提示', () {
      testWidgets('非空分类应该显示警告信息', (WidgetTester tester) async {
        // Arrange
        final category = MockCategory();
        const itemCount = 3;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DeleteCategoryDialog(
                category: category,
                itemCount: itemCount,
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
        expect(find.text('分类"${category.displayName}"下还有 $itemCount 个项目。'), findsOneWidget);
        expect(find.text('请先清空或移动这些项目后再删除分类。'), findsOneWidget);
      });

      testWidgets('非空分类不应该显示删除按钮', (WidgetTester tester) async {
        // Arrange
        final category = MockCategory();
        const itemCount = 3;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DeleteCategoryDialog(
                category: category,
                itemCount: itemCount,
              ),
            ),
          ),
        );

        // Assert - 只应该有取消按钮，没有删除按钮
        expect(find.text('取消'), findsOneWidget);
        expect(find.text('删除'), findsNothing);
      });
    });
  });
}
