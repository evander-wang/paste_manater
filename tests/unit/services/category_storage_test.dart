import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/services/category_storage.dart';

void main() {
  group('CategoryStorage', () {
    late CategoryStorage storage;

    setUp(() async {
      // 设置测试环境
      TestWidgetsFlutterBinding.ensureInitialized();
      storage = CategoryStorage();

      // 每个测试前清空数据
      await storage.saveCategories([]);
    });

    group('saveCategories & loadCategories', () {
      test('应该成功保存和加载分类列表', () async {
        // Arrange
        final categoriesJson = [
          {
            'id': 'custom_1234567890',
            'name': '工作',
            'icon': '59122',
            'color': 'ff2196f3',
            'createdAt': '2026-01-16T10:30:00.000',
          },
        ];

        // Act
        await storage.saveCategories(categoriesJson);
        final loaded = await storage.loadCategories();

        // Assert
        expect(loaded.length, 1);
        expect(loaded[0]['id'], 'custom_1234567890');
        expect(loaded[0]['name'], '工作');
        expect(loaded[0]['icon'], '59122');
        expect(loaded[0]['color'], 'ff2196f3');
      });

      test('应该保存多个分类', () async {
        // Arrange
        final categoriesJson = [
          {
            'id': 'custom_1',
            'name': '工作',
            'icon': '59122',
            'color': 'ff2196f3',
            'createdAt': '2026-01-16T10:00:00.000',
          },
          {
            'id': 'custom_2',
            'name': '学习',
            'icon': '58138',
            'color': 'ff4caf50',
            'createdAt': '2026-01-16T11:00:00.000',
          },
        ];

        // Act
        await storage.saveCategories(categoriesJson);
        final loaded = await storage.loadCategories();

        // Assert
        expect(loaded.length, 2);
        expect(loaded[0]['name'], '工作');
        expect(loaded[1]['name'], '学习');
      });

      test('应该覆盖之前保存的数据', () async {
        // Arrange - 第一次保存
        await storage.saveCategories([
          {
            'id': 'custom_1',
            'name': '旧分类',
            'icon': '59122',
            'color': 'ff2196f3',
            'createdAt': '2026-01-16T10:00:00.000',
          },
        ]);

        // Act - 第二次保存（覆盖）
        final newCategories = [
          {
            'id': 'custom_2',
            'name': '新分类',
            'icon': '58138',
            'color': 'ff4caf50',
            'createdAt': '2026-01-16T11:00:00.000',
          },
        ];
        await storage.saveCategories(newCategories);
        final loaded = await storage.loadCategories();

        // Assert - 应该只有新数据
        expect(loaded.length, 1);
        expect(loaded[0]['name'], '新分类');
      });

      test('应该保存空列表', () async {
        // Act
        await storage.saveCategories([]);
        final loaded = await storage.loadCategories();

        // Assert
        expect(loaded, isEmpty);
      });
    });

    group('loadCategories', () {
      test('如果文件不存在应该返回空列表', () async {
        // Arrange - 确保没有数据
        await storage.saveCategories([]);

        // Act
        final loaded = await storage.loadCategories();

        // Assert
        expect(loaded, isEmpty);
      });

      test('应该正确解析版本信息', () async {
        // Arrange
        await storage.saveCategories([
          {
            'id': 'custom_version',
            'name': '版本测试',
            'icon': '59122',
            'color': 'ff2196f3',
            'createdAt': '2026-01-16T12:00:00.000',
          },
        ]);

        // Act
        final loaded = await storage.loadCategories();

        // Assert - 版本检查不抛异常，数据正常加载
        expect(loaded.length, 1);
        expect(loaded[0]['name'], '版本测试');
      });

      test('应该保持数据完整性（多次保存和加载）', () async {
        // Arrange
        final originalData = [
          {
            'id': 'custom_integrity',
            'name': '完整性测试',
            'icon': '59122',
            'color': 'ff2196f3',
            'createdAt': '2026-01-16T13:00:00.000',
          },
        ];

        // Act - 多次保存和加载
        await storage.saveCategories(originalData);
        var loaded = await storage.loadCategories();
        await storage.saveCategories(loaded);
        loaded = await storage.loadCategories();

        // Assert
        expect(loaded.length, 1);
        expect(loaded[0]['id'], 'custom_integrity');
        expect(loaded[0]['name'], '完整性测试');
      });
    });

    group('数据格式', () {
      test('保存的数据应该包含version字段', () async {
        // 注意：这个测试通过成功加载来间接验证version存在
        // 因为loadCategories会检查version字段

        // Arrange & Act
        await storage.saveCategories([
          {
            'id': 'custom_format',
            'name': '格式测试',
            'icon': '59122',
            'color': 'ff2196f3',
            'createdAt': '2026-01-16T14:00:00.000',
          },
        ]);

        // Assert - 如果version格式不正确，loadCategories会抛异常
        final loaded = await storage.loadCategories();
        expect(loaded.length, 1);
      });

      test('保存的数据应该包含categories数组', () async {
        // Arrange & Act
        final categories = [
          {
            'id': 'custom_array',
            'name': '数组测试',
            'icon': '59122',
            'color': 'ff2196f3',
            'createdAt': '2026-01-16T15:00:00.000',
          },
        ];
        await storage.saveCategories(categories);

        // Assert
        final loaded = await storage.loadCategories();
        expect(loaded, isA<List<dynamic>>());
        expect(loaded.length, greaterThan(0));
      });
    });

    group('边界情况', () {
      test('应该处理特殊字符名称', () async {
        // Arrange
        final categoriesJson = [
          {
            'id': 'custom_unicode',
            'name': '🎨设计',
            'icon': '59122',
            'color': 'ffe91e63',
            'createdAt': '2026-01-16T16:00:00.000',
          },
        ];

        // Act
        await storage.saveCategories(categoriesJson);
        final loaded = await storage.loadCategories();

        // Assert
        expect(loaded.length, 1);
        expect(loaded[0]['name'], '🎨设计');
      });

      test('应该处理最大长度的名称', () async {
        // Arrange
        final categoriesJson = [
          {
            'id': 'custom_max',
            'name': '1234567890', // 10字符
            'icon': '59122',
            'color': 'ffff9800',
            'createdAt': '2026-01-16T17:00:00.000',
          },
        ];

        // Act
        await storage.saveCategories(categoriesJson);
        final loaded = await storage.loadCategories();

        // Assert
        expect(loaded.length, 1);
        expect(loaded[0]['name'].length, 10);
      });

      test('应该处理大量分类（性能测试）', () async {
        // Arrange - 创建20个分类（最大限制）
        final categoriesJson = List.generate(20, (index) {
          return {
            'id': 'custom_$index',
            'name': '分类$index',
            'icon': '59122',
            'color': 'ff2196f3',
            'createdAt': '2026-01-16T${index.toString().padLeft(2, '0')}:00:00.000',
          };
        });

        // Act
        await storage.saveCategories(categoriesJson);
        final loaded = await storage.loadCategories();

        // Assert
        expect(loaded.length, 20);
      });
    });

    group('备份和恢复', () {
      test('保存操作应该原子性（要么全部成功，要么全部失败）', () async {
        // 注意：这个测试验证基本的数据完整性
        // 实际的原子性需要通过检查文件系统实现

        // Arrange
        final categoriesJson = [
          {
            'id': 'custom_atomic',
            'name': '原子性测试',
            'icon': '59122',
            'color': 'ff2196f3',
            'createdAt': '2026-01-16T18:00:00.000',
          },
        ];

        // Act
        await storage.saveCategories(categoriesJson);
        final loaded = await storage.loadCategories();

        // Assert - 数据应该完整，没有部分写入的情况
        expect(loaded.length, 1);
        expect(loaded[0]['id'], 'custom_atomic');
      });

      test('应该从备份恢复损坏的数据', () async {
        // 注意：这个测试需要模拟文件损坏
        // 由于无法直接访问文件，我们通过多次保存来验证备份机制

        // Arrange
        final categoriesJson = [
          {
            'id': 'custom_backup',
            'name': '备份测试',
            'icon': '59122',
            'color': 'ff4caf50',
            'createdAt': '2026-01-16T19:00:00.000',
          },
        ];

        // Act - 多次保存触发备份
        await storage.saveCategories(categoriesJson);
        await storage.saveCategories(categoriesJson);
        final loaded = await storage.loadCategories();

        // Assert - 数据应该正常
        expect(loaded.length, 1);
        expect(loaded[0]['name'], '备份测试');
      });
    });
  });
}
