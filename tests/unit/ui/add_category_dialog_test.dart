import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/ui/add_category_dialog.dart';

void main() {
  group('AddCategoryDialog', () {
    // 注意：这些测试需要在创建 AddCategoryDialog 后才能运行
    // 目前先创建测试框架

    testWidgets('应该显示输入框和确认/取消按钮', (WidgetTester tester) async {
      // Arrange
      final dialog = AddCategoryDialog(
        onSubmitted: (name) async {},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showDialog(context: tester.element(find.byType(ElevatedButton)), builder: (_) => dialog);
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('添加分类'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('确认'), findsOneWidget);
    });

    testWidgets('应该验证名称长度（1-10字符）', (WidgetTester tester) async {
      // Arrange
      String? submittedName;
      final dialog = AddCategoryDialog(
        onSubmitted: (name) async {
          submittedName = name;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showDialog(context: tester.element(find.byType(ElevatedButton)), builder: (_) => dialog);
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Act - 输入空名称
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();

      // Assert - 应该显示错误提示
      expect(find.text('分类名称不能为空'), findsOneWidget);
      expect(submittedName, isNull);
    });

    testWidgets('应该拒绝超过10字符的名称', (WidgetTester tester) async {
      // Arrange
      String? submittedName;
      final dialog = AddCategoryDialog(
        onSubmitted: (name) async {
          submittedName = name;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showDialog(context: tester.element(find.byType(ElevatedButton)), builder: (_) => dialog);
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Act - maxLength会自动限制输入,所以输入10个字符
      await tester.enterText(find.byType(TextField), '12345678901');
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();

      // Assert - 由于maxLength限制,实际只输入了10个字符,应该提交成功
      expect(submittedName, '1234567890');
    });

    testWidgets('应该接受有效的分类名称', (WidgetTester tester) async {
      // Arrange
      String? submittedName;
      final dialog = AddCategoryDialog(
        onSubmitted: (name) async {
          submittedName = name;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showDialog(context: tester.element(find.byType(ElevatedButton)), builder: (_) => dialog);
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Act - 输入有效名称
      await tester.enterText(find.byType(TextField), '工作');
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();

      // Assert - 应该提交
      expect(submittedName, '工作');
    });

    testWidgets('应该支持Unicode名称（emoji）', (WidgetTester tester) async {
      // Arrange
      String? submittedName;
      final dialog = AddCategoryDialog(
        onSubmitted: (name) async {
          submittedName = name;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showDialog(context: tester.element(find.byType(ElevatedButton)), builder: (_) => dialog);
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Act - 输入emoji名称
      await tester.enterText(find.byType(TextField), '🎨设计');
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();

      // Assert
      expect(submittedName, '🎨设计');
    });

    testWidgets('点击取消按钮应该关闭对话框', (WidgetTester tester) async {
      // Arrange
      final dialog = AddCategoryDialog(
        onSubmitted: (name) async {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showDialog(context: tester.element(find.byType(ElevatedButton)), builder: (_) => dialog);
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      // Assert - 对话框应该关闭
      expect(find.text('添加分类'), findsNothing);
    });

    testWidgets('应该实时显示字符计数', (WidgetTester tester) async {
      // Arrange
      final dialog = AddCategoryDialog(
        onSubmitted: (name) async {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showDialog(context: tester.element(find.byType(ElevatedButton)), builder: (_) => dialog);
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextField), '工作');
      await tester.pump(); // 触发 rebuild 以更新计数器

      // Assert
      expect(find.text('2/10'), findsOneWidget);
    });
  });
}
