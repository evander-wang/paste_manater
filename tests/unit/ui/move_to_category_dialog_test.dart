import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/models/category_base.dart';
import 'package:paste_manager/models/category.dart';
import 'package:paste_manager/models/custom_category.dart';
import 'package:paste_manager/services/category_manager.dart';
import 'package:paste_manager/services/category_storage.dart';
import 'package:paste_manager/ui/move_to_category_dialog.dart';

class MockCategoryManager extends CategoryManager {
  final List<CategoryBase> _categories;

  MockCategoryManager(this._categories) : super(
    storage: _MockCategoryStorage(),
  );

  @override
  List<CategoryBase> getAllCategories() => _categories;

  @override
  CategoryBase? getCategoryById(String id) {
    for (final cat in _categories) {
      if (cat.id == id) {
        return cat;
      }
    }
    return null;
  }
}

class _MockCategoryStorage extends CategoryStorage {
  @override
  Future<List<Map<String, dynamic>>> loadCategories() async => [];

  @override
  Future<void> saveCategories(List<Map<String, dynamic>> categories) async {}

  @override
  Future<void> removeCategory(
    List<Map<String, dynamic>> categories,
    String categoryId,
  ) async {}

  @override
  Future<void> backupCategories() async {}
}

void main() {
  group('T057: MoveToCategoryDialog Widget测试', () {
    group('分类选择列表', () {
      testWidgets('应该显示所有预置和自定义分类', (WidgetTester tester) async {
        // Arrange
        final categories = <CategoryBase>[
          PresetCategoryAdapter(Category.text),
          PresetCategoryAdapter(Category.link),
          CustomCategoryAdapter(
            CustomCategory(
              id: 'custom_1',
              name: '工作',
              icon: Icons.work,
              color: Colors.blue,
              createdAt: DateTime.now(),
            ),
          ),
          CustomCategoryAdapter(
            CustomCategory(
              id: 'custom_2',
              name: '个人',
              icon: Icons.person,
              color: Colors.green,
              createdAt: DateTime.now(),
            ),
          ),
        ];

        final mockManager = MockCategoryManager(categories);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MoveToCategoryDialog(
                categoryManager: mockManager,
                currentCategoryId: null,
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('文本'), findsOneWidget);
        expect(find.text('链接'), findsOneWidget);
        expect(find.text('工作'), findsOneWidget);
        expect(find.text('个人'), findsOneWidget);
      });

      testWidgets('应该显示每个分类的图标和名称', (WidgetTester tester) async {
        // Arrange
        final categories = <CategoryBase>[
          CustomCategoryAdapter(
            CustomCategory(
              id: 'custom_1',
              name: '工作',
              icon: Icons.work,
              color: Colors.blue,
              createdAt: DateTime.now(),
            ),
          ),
        ];

        final mockManager = MockCategoryManager(categories);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MoveToCategoryDialog(
                categoryManager: mockManager,
                currentCategoryId: null,
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.work), findsOneWidget);
        expect(find.text('工作'), findsOneWidget);
      });
    });

    group('选择交互', () {
      testWidgets('点击分类应该返回categoryId并关闭对话框', (WidgetTester tester) async {
        // Arrange
        final categories = <CategoryBase>[
          PresetCategoryAdapter(Category.text),
          CustomCategoryAdapter(
            CustomCategory(
              id: 'custom_1',
              name: '工作',
              icon: Icons.work,
              color: Colors.blue,
              createdAt: DateTime.now(),
            ),
          ),
        ];

        final mockManager = MockCategoryManager(categories);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MoveToCategoryDialog(
                categoryManager: mockManager,
                currentCategoryId: null,
              ),
            ),
          ),
        );

        // Act - 点击"工作"分类
        await tester.tap(find.text('工作'));
        await tester.pumpAndSettle();

        // Assert - 对话框应该关闭
        expect(find.byType(MoveToCategoryDialog), findsNothing);
      });

      testWidgets('点击当前分类应该只显示提示', (WidgetTester tester) async {
        // Arrange
        final categories = <CategoryBase>[
          PresetCategoryAdapter(Category.text),
          CustomCategoryAdapter(
            CustomCategory(
              id: 'custom_1',
              name: '工作',
              icon: Icons.work,
              color: Colors.blue,
              createdAt: DateTime.now(),
            ),
          ),
        ];

        final mockManager = MockCategoryManager(categories);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MoveToCategoryDialog(
                categoryManager: mockManager,
                currentCategoryId: 'custom_1',
              ),
            ),
          ),
        );

        // Assert - 应该显示当前分类标签
        expect(find.text('当前: 工作'), findsOneWidget);
        expect(find.text('当前所在分类'), findsOneWidget);
      });
    });

    group('对话框标题', () {
      testWidgets('应该显示"移动到分类"标题', (WidgetTester tester) async {
        // Arrange
        final categories = <CategoryBase>[
          PresetCategoryAdapter(Category.text),
        ];

        final mockManager = MockCategoryManager(categories);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MoveToCategoryDialog(
                categoryManager: mockManager,
                currentCategoryId: null,
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('移动到分类'), findsOneWidget);
      });

      testWidgets('应该显示取消按钮', (WidgetTester tester) async {
        // Arrange
        final categories = <CategoryBase>[
          PresetCategoryAdapter(Category.text),
        ];

        final mockManager = MockCategoryManager(categories);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MoveToCategoryDialog(
                categoryManager: mockManager,
                currentCategoryId: null,
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('取消'), findsOneWidget);
      });
    });
  });
}
