import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/services/pin_service.dart';
import 'package:paste_manager/models/command.dart';
import 'package:paste_manager/models/clipboard_item.dart';
import 'package:paste_manager/models/category.dart';

void main() {
  group('PinService', () {
    late PinService pinService;

    setUp(() {
      pinService = PinService();
    });

    group('置顶/取消置顶 - Command', () {
      test('应该正确置顶Command项目', () {
        // Arrange
        final now = DateTime.now();
        final item = Command(
          id: '1',
          name: 'Test Command',
          command: 'npm test',
          createdAt: now,
          modifiedAt: now,
        );

        // Act
        final result = pinService.pin(item);

        // Assert
        expect(result.isPinned, true);
        expect(result.pinnedAt, isNotNull);
        expect(result.pinnedAt!.isBefore(DateTime.now()), true);
        expect(result.pinnedAt!.isAfter(DateTime.now().subtract(const Duration(seconds: 1))), true);
      });

      test('应该正确取消置顶Command项目', () {
        // Arrange
        final now = DateTime.now();
        final item = Command(
          id: '1',
          name: 'Test Command',
          command: 'npm test',
          createdAt: now,
          modifiedAt: now,
          pinned: true,
          pinnedAt: now.subtract(const Duration(hours: 1)),
        );

        // Act
        final result = pinService.unpin(item);

        // Assert
        expect(result.isPinned, false);
        expect(result.pinnedAt, null);
      });

      test('应该能够重新置顶已取消置顶的Command', () {
        // Arrange
        final now = DateTime.now();
        final item = Command(
          id: '1',
          name: 'Test Command',
          command: 'npm test',
          createdAt: now,
          modifiedAt: now,
          pinned: false,
          pinnedAt: now.subtract(const Duration(hours: 1)),
        );

        // Act
        final result = pinService.pin(item);

        // Assert
        expect(result.isPinned, true);
        expect(result.pinnedAt, isNotNull);
        // 新的置顶时间应该比旧的更晚
        expect(result.pinnedAt!.isAfter(DateTime.now().subtract(const Duration(seconds: 1))), true);
      });
    });

    group('置顶/取消置顶 - ClipboardItem', () {
      test('应该正确置顶ClipboardItem项目', () {
        // Arrange
        final now = DateTime.now();
        final item = ClipboardItem(
          id: '1',
          content: 'test content',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: now,
          hash: 'abc123',
          size: 12,
        );

        // Act
        final result = pinService.pin(item);

        // Assert
        expect(result.isPinned, true);
        expect(result.pinnedAt, isNotNull);
        expect(result.pinnedAt!.isBefore(DateTime.now()), true);
        expect(result.pinnedAt!.isAfter(DateTime.now().subtract(const Duration(seconds: 1))), true);
      });

      test('应该正确取消置顶ClipboardItem项目', () {
        // Arrange
        final now = DateTime.now();
        final item = ClipboardItem(
          id: '1',
          content: 'test content',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: now,
          hash: 'abc123',
          size: 12,
          pinned: true,
          pinnedAt: now.subtract(const Duration(hours: 1)),
        );

        // Act
        final result = pinService.unpin(item);

        // Assert
        expect(result.isPinned, false);
        expect(result.pinnedAt, null);
      });
    });

    group('排序功能 - Command', () {
      test('应该按置顶状态排序:置顶项目在前', () {
        // Arrange
        final now = DateTime.now();
        final item1 = Command(
          id: '1',
          name: 'Item 1',
          command: 'cmd1',
          createdAt: now,
          modifiedAt: now,
        );
        final item2 = Command(
          id: '2',
          name: 'Item 2',
          command: 'cmd2',
          createdAt: now,
          modifiedAt: now,
          pinned: true,
          pinnedAt: now.subtract(const Duration(hours: 2)),
        );
        final item3 = Command(
          id: '3',
          name: 'Item 3',
          command: 'cmd3',
          createdAt: now,
          modifiedAt: now,
          pinned: true,
          pinnedAt: now.subtract(const Duration(hours: 1)),
        );
        final items = [item1, item2, item3];

        // Act
        final result = pinService.sortByPinStatus(items);

        // Assert
        expect(result.length, 3);
        // 第一个应该是最近置顶的(item3)
        expect(result[0].id, '3');
        expect(result[0].isPinned, true);
        // 第二个应该是较早置顶的(item2)
        expect(result[1].id, '2');
        expect(result[1].isPinned, true);
        // 第三个应该是未置顶的(item1)
        expect(result[2].id, '1');
        expect(result[2].isPinned, false);
      });

      test('应该按置顶时间倒序排列置顶项目', () {
        // Arrange
        final now = DateTime.now();
        final item1 = Command(
          id: '1',
          name: 'Item 1',
          command: 'cmd1',
          createdAt: now,
          modifiedAt: now,
          pinned: true,
          pinnedAt: now.subtract(const Duration(hours: 3)),
        );
        final item2 = Command(
          id: '2',
          name: 'Item 2',
          command: 'cmd2',
          createdAt: now,
          modifiedAt: now,
          pinned: true,
          pinnedAt: now.subtract(const Duration(hours: 1)),
        );
        final item3 = Command(
          id: '3',
          name: 'Item 3',
          command: 'cmd3',
          createdAt: now,
          modifiedAt: now,
          pinned: true,
          pinnedAt: now.subtract(const Duration(hours: 2)),
        );
        final items = [item1, item2, item3];

        // Act
        final result = pinService.sortByPinStatus(items);

        // Assert
        // 应该按置顶时间倒序: item2(1小时前) -> item3(2小时前) -> item1(3小时前)
        expect(result[0].id, '2');
        expect(result[1].id, '3');
        expect(result[2].id, '1');
      });

      test('空列表应该返回空列表', () {
        // Arrange
        final items = <Command>[];

        // Act
        final result = pinService.sortByPinStatus(items);

        // Assert
        expect(result, isEmpty);
      });

      test('全部未置顶的项目应该保持原有顺序', () {
        // Arrange
        final now = DateTime.now();
        final item1 = Command(
          id: '1',
          name: 'Item 1',
          command: 'cmd1',
          createdAt: now,
          modifiedAt: now,
        );
        final item2 = Command(
          id: '2',
          name: 'Item 2',
          command: 'cmd2',
          createdAt: now,
          modifiedAt: now,
        );
        final item3 = Command(
          id: '3',
          name: 'Item 3',
          command: 'cmd3',
          createdAt: now,
          modifiedAt: now,
        );
        final items = [item1, item2, item3];

        // Act
        final result = pinService.sortByPinStatus(items);

        // Assert
        expect(result.length, 3);
        expect(result[0].id, '1');
        expect(result[1].id, '2');
        expect(result[2].id, '3');
      });

      test('全部置顶的项目应该按置顶时间倒序', () {
        // Arrange
        final now = DateTime.now();
        final item1 = Command(
          id: '1',
          name: 'Item 1',
          command: 'cmd1',
          createdAt: now,
          modifiedAt: now,
          pinned: true,
          pinnedAt: now.subtract(const Duration(minutes: 10)),
        );
        final item2 = Command(
          id: '2',
          name: 'Item 2',
          command: 'cmd2',
          createdAt: now,
          modifiedAt: now,
          pinned: true,
          pinnedAt: now.subtract(const Duration(minutes: 5)),
        );
        final items = [item1, item2];

        // Act
        final result = pinService.sortByPinStatus(items);

        // Assert
        expect(result.length, 2);
        expect(result[0].id, '2'); // 最近置顶的在前
        expect(result[1].id, '1');
      });
    });

    group('边界情况', () {
      test('单个项目列表应该正常工作', () {
        // Arrange
        final now = DateTime.now();
        final item = Command(
          id: '1',
          name: 'Item 1',
          command: 'cmd1',
          createdAt: now,
          modifiedAt: now,
        );
        final items = [item];

        // Act
        final result = pinService.sortByPinStatus(items);

        // Assert
        expect(result.length, 1);
        expect(result[0].id, '1');
      });
    });
  });
}
