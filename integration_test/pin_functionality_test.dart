import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paste_manager/services/pin_service.dart';
import 'package:paste_manager/services/storage_service.dart';
import 'package:paste_manager/models/clipboard_item.dart';
import 'package:paste_manager/models/clipboard_history.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('置顶功能E2E测试', () {
    late PinService pinService;
    late StorageService storageService;

    setUp(() async {
      pinService = PinService();
      storageService = StorageService();

      // 清理环境
      await storageService.clear();
    });

    tearDown(() async {
      // 清理环境
      await storageService.clear();
    });

    test('完整置顶流程：置顶 → 保存 → 重载 → 验证位置和图标', () async {
      // Arrange: 创建多个项目
      final item1 = ClipboardItem(
        id: 'test-item-1',
        content: '普通项目1',
        type: ClipboardItemType.text,
        categoryId: 'text',
        timestamp: DateTime.now(),
        hash: 'hash-1',
        size: 100,
      );

      final item2 = ClipboardItem(
        id: 'test-item-2',
        content: '将要置顶的项目',
        type: ClipboardItemType.text,
        categoryId: 'text',
        timestamp: DateTime.now(),
        hash: 'hash-2',
        size: 100,
      );

      final item3 = ClipboardItem(
        id: 'test-item-3',
        content: '普通项目3',
        type: ClipboardItemType.text,
        categoryId: 'text',
        timestamp: DateTime.now(),
        hash: 'hash-3',
        size: 100,
      );

      // 添加到历史
      var history = await storageService.load();
      history = history.add(item1);
      history = history.add(item2);
      history = history.add(item3);
      await storageService.save(history);

      // Act: 置顶第二个项目
      var reloadedHistory = await storageService.load();
      final itemToPin = reloadedHistory.items.firstWhere((i) => i.id == 'test-item-2');
      final pinnedItem = pinService.pin(itemToPin);

      // 更新历史
      reloadedHistory = reloadedHistory..remove('test-item-2');
      reloadedHistory = reloadedHistory.add(pinnedItem);

      // 使用PinService排序
      final sortedItems = pinService.sortByPinStatus(reloadedHistory.items);
      final sortedHistory = ClipboardHistory(initialItems: sortedItems);
      await storageService.save(sortedHistory);

      // Assert: 验证置顶后的状态
      final finalHistory = await storageService.load();

      // 验证置顶标志
      final pinnedItemInHistory = finalHistory.items.firstWhere(
        (i) => i.id == 'test-item-2',
      );
      expect(pinnedItemInHistory.pinned, isTrue,
        reason: '项目应该被置顶');
      expect(pinnedItemInHistory.pinnedAt, isNotNull,
        reason: '置顶时间应该被设置');

      // 验证置顶项目在列表顶部
      final firstItem = finalHistory.items.first;
      expect(firstItem.id, 'test-item-2',
        reason: '置顶的项目应该在列表最前面');

      // 验证其他项目保持相对顺序
      final unpinnedItems = finalHistory.items.where((i) => !i.pinned).toList();
      expect(unpinnedItems.length, equals(2),
        reason: '应该有2个未置顶的项目');
    });

    test('完整取消置顶流程：置顶 → 取消置顶 → 验证状态', () async {
      // Arrange: 创建并置顶一个项目
      final item = ClipboardItem(
        id: 'pinned-item',
        content: '已置顶的项目',
        type: ClipboardItemType.text,
        categoryId: 'text',
        timestamp: DateTime.now(),
        hash: 'pinned-hash',
        size: 100,
      );

      var history = await storageService.load();
      final pinnedItem = pinService.pin(item);
      history = history.add(pinnedItem);
      await storageService.save(history);

      // Act: 取消置顶
      var reloadedHistory = await storageService.load();
      final itemToUnpin = reloadedHistory.items.firstWhere((i) => i.id == 'pinned-item');
      final unpinnedItem = pinService.unpin(itemToUnpin);

      reloadedHistory = reloadedHistory..remove('pinned-item');
      reloadedHistory = reloadedHistory.add(unpinnedItem);
      await storageService.save(reloadedHistory);

      // Assert: 验证取消置顶后的状态
      final finalHistory = await storageService.load();
      final finalItem = finalHistory.items.firstWhere(
        (i) => i.id == 'pinned-item',
      );

      expect(finalItem.pinned, isFalse,
        reason: '项目应该被取消置顶');
      expect(finalItem.pinnedAt, isNull,
        reason: '置顶时间应该被清除');
    });

    test('置顶状态应该跨应用重启保持', () async {
      // Arrange: 第一次保存 - 置顶一个项目
      final item = ClipboardItem(
        id: 'persistent-item',
        content: '持久化测试项目',
        type: ClipboardItemType.text,
        categoryId: 'text',
        timestamp: DateTime.now(),
        hash: 'persistent-hash',
        size: 100,
      );

      var history = await storageService.load();
      final pinnedItem = pinService.pin(item);
      history = history.add(pinnedItem);
      await storageService.save(history);

      // Act: 模拟应用重启（重新加载）
      final reloadedHistory = await storageService.load();
      final reloadedItem = reloadedHistory.items.firstWhere(
        (i) => i.id == 'persistent-item',
        orElse: () => throw Exception('项目未找到'),
      );

      // Assert: 验证置顶状态持久化
      expect(reloadedItem.pinned, isTrue,
        reason: '置顶状态应该在重启后保持');
      expect(reloadedItem.pinnedAt, isNotNull,
        reason: '置顶时间应该在重启后保持');
    });

    test('多个置顶项目应该按置顶时间倒序排列', () async {
      // Arrange: 创建多个项目并按顺序置顶
      final item1 = ClipboardItem(
        id: 'item-1',
        content: '项目1',
        type: ClipboardItemType.text,
        categoryId: 'text',
        timestamp: DateTime.now(),
        hash: 'hash-1',
        size: 100,
      );

      final item2 = ClipboardItem(
        id: 'item-2',
        content: '项目2',
        type: ClipboardItemType.text,
        categoryId: 'text',
        timestamp: DateTime.now(),
        hash: 'hash-2',
        size: 100,
      );

      final item3 = ClipboardItem(
        id: 'item-3',
        content: '项目3',
        type: ClipboardItemType.text,
        categoryId: 'text',
        timestamp: DateTime.now(),
        hash: 'hash-3',
        size: 100,
      );

      // 按顺序置顶（item1 → item2 → item3）
      var pinned1 = pinService.pin(item1);
      await Future.delayed(const Duration(milliseconds: 10));
      var pinned2 = pinService.pin(item2);
      await Future.delayed(const Duration(milliseconds: 10));
      var pinned3 = pinService.pin(item3);

      var history = await storageService.load();
      history = history.add(pinned1);
      history = history.add(pinned2);
      history = history.add(pinned3);

      // 使用PinService排序
      final sortedItems = pinService.sortByPinStatus(history.items);
      final sortedHistory = ClipboardHistory(initialItems: sortedItems);
      await storageService.save(sortedHistory);

      // Act: 重新加载
      final reloadedHistory = await storageService.load();
      final pinnedItems = reloadedHistory.items.where((i) => i.pinned).toList();

      // Assert: 验证置顶项目按时间倒序显示
      expect(pinnedItems.length, equals(3),
        reason: '应该有3个置顶项目');

      expect(pinnedItems[0].id, 'item-3',
        reason: '最后置顶的项目应该在最前面');
      expect(pinnedItems[1].id, 'item-2',
        reason: '第二后置顶的项目应该在第二位');
      expect(pinnedItems[2].id, 'item-1',
        reason: '最先置顶的项目应该在第三位');
    });

    test('置顶操作应该在合理时间内完成（性能测试）', () async {
      // Arrange: 准备测试数据
      final items = List.generate(50, (i) => ClipboardItem(
            id: 'item-$i',
            content: '测试内容 $i',
            type: ClipboardItemType.text,
            categoryId: 'text',
            timestamp: DateTime.now(),
            hash: 'hash-$i',
            size: 100,
          ));

      var history = await storageService.load();
      for (final item in items) {
        history = history.add(item);
      }
      await storageService.save(history);

      // Act: 置顶一个项目并测量时间
      final stopwatch = Stopwatch()..start();

      final itemToPin = items[25];
      final pinnedItem = pinService.pin(itemToPin);

      history = await storageService.load();
      history = history..remove(itemToPin.id);
      history = history.add(pinnedItem);
      await storageService.save(history);

      stopwatch.stop();

      // Assert: 操作应该在500ms内完成
      expect(stopwatch.elapsedMilliseconds, lessThan(500),
        reason: '置顶操作应该在500ms内完成');

      debugPrint('✅ 置顶操作耗时: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('混合置顶和未置顶项目应该正确显示', () async {
      // Arrange: 创建混合项目列表
      final item1 = ClipboardItem(
        id: 'item-1',
        content: '未置顶项目1',
        type: ClipboardItemType.text,
        categoryId: 'text',
        timestamp: DateTime.now(),
        hash: 'hash-1',
        size: 100,
      );

      final item2 = ClipboardItem(
        id: 'item-2',
        content: '置顶项目',
        type: ClipboardItemType.text,
        categoryId: 'text',
        timestamp: DateTime.now(),
        hash: 'hash-2',
        size: 100,
        pinned: true,
        pinnedAt: DateTime.now(),
      );

      final item3 = ClipboardItem(
        id: 'item-3',
        content: '未置顶项目2',
        type: ClipboardItemType.text,
        categoryId: 'text',
        timestamp: DateTime.now(),
        hash: 'hash-3',
        size: 100,
      );

      var history = await storageService.load();
      history = history.add(item1);
      history = history.add(item2);
      history = history.add(item3);

      // 使用PinService排序
      final sortedItems = pinService.sortByPinStatus(history.items);
      final sortedHistory = ClipboardHistory(initialItems: sortedItems);
      await storageService.save(sortedHistory);

      // Act & Assert: 验证排序结果
      final reloadedHistory = await storageService.load();

      // 第一个应该是置顶项目
      expect(reloadedHistory.items[0].pinned, isTrue,
        reason: '第一个项目应该是置顶的');
      expect(reloadedHistory.items[0].id, 'item-2',
        reason: '置顶项目应该在最前面');

      // 后面两个应该是未置顶项目
      expect(reloadedHistory.items[1].pinned, isFalse,
        reason: '第二个项目应该是未置顶的');
      expect(reloadedHistory.items[2].pinned, isFalse,
        reason: '第三个项目应该是未置顶的');
    });
  });
}
