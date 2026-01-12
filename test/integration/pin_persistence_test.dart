import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/services/pin_service.dart';
import 'package:paste_manager/models/clipboard_item.dart';
import 'package:paste_manager/models/clipboard_history.dart';
import 'package:paste_manager/models/category.dart';
import 'package:paste_manager/services/storage_service.dart';

void main() {
  // 初始化 Flutter test binding
  TestWidgetsFlutterBinding.ensureInitialized();

  group('置顶持久化集成测试', () {
    late PinService pinService;
    late StorageService storageService;

    setUp(() async {
      // 初始化服务
      pinService = PinService();
      storageService = StorageService();

      // 清理环境
      await storageService.clear();
    });

    tearDown(() async {
      // 清理环境
      await storageService.clear();
    });

    test('应该持久化剪贴板项目置顶状态（重启后保持）', () async {
      // Arrange: 创建并置顶剪贴板项目
      final item = ClipboardItem(
        id: 'test-item-1',
        content: '测试内容',
        type: ClipboardItemType.text,
        category: Category.text,
        timestamp: DateTime.now(),
        hash: 'test-hash-1',
        size: 100,
      );

      // 加载当前历史并添加项目
      final history = await storageService.load();
      final updatedHistory = history.add(item);

      // 置顶项目（使用PinService）
      final pinnedItem = pinService.pin(item);

      // 更新历史中的项目
      final historyWithPinned = updatedHistory..remove(item.id);
      final finalHistory = historyWithPinned.add(pinnedItem);
      await storageService.save(finalHistory);

      // Act: 模拟应用重启（重新加载）
      final reloadedHistory = await storageService.load();

      // Assert: 验证置顶状态持久化
      final reloadedItem = reloadedHistory.items.firstWhere(
        (i) => i.id == item.id,
        orElse: () => throw Exception('项目未找到'),
      );

      expect(reloadedItem.pinned, isTrue,
        reason: '剪贴板项目置顶状态应该在重启后保持');
      expect(reloadedItem.pinnedAt, isNotNull,
        reason: '剪贴板项目置顶时间应该在重启后保持');

      // 验证置顶项目排在列表前面
      final firstItem = reloadedHistory.items.first;
      expect(firstItem.pinned, isTrue,
        reason: '置顶的项目应该排在列表最前面');
    });

    test('应该持久化多个置顶项目的排序（按置顶时间倒序）', () async {
      // Arrange: 创建多个剪贴板项目并置顶
      final item1 = ClipboardItem(
        id: 'test-item-1',
        content: '内容1',
        type: ClipboardItemType.text,
        category: Category.text,
        timestamp: DateTime.now(),
        hash: 'test-hash-1',
        size: 100,
      );

      final item2 = ClipboardItem(
        id: 'test-item-2',
        content: '内容2',
        type: ClipboardItemType.text,
        category: Category.text,
        timestamp: DateTime.now(),
        hash: 'test-hash-2',
        size: 100,
      );

      final item3 = ClipboardItem(
        id: 'test-item-3',
        content: '内容3',
        type: ClipboardItemType.text,
        category: Category.text,
        timestamp: DateTime.now(),
        hash: 'test-hash-3',
        size: 100,
      );

      // 添加所有项目到历史
      var history = await storageService.load();
      history = history.add(item1);
      history = history.add(item2);
      history = history.add(item3);

      // 按顺序置顶（item1 -> item2 -> item3）
      var pinned1 = pinService.pin(item1);
      await Future.delayed(const Duration(milliseconds: 10));
      var pinned2 = pinService.pin(item2);
      await Future.delayed(const Duration(milliseconds: 10));
      var pinned3 = pinService.pin(item3);

      // 更新历史
      history = history..remove(item1.id)..remove(item2.id)..remove(item3.id);
      history = history.add(pinned1);
      history = history.add(pinned2);
      history = history.add(pinned3);

      // 使用PinService排序
      final sortedHistory = pinService.sortByPinStatus(history.items);

      // 创建新的历史对象（直接使用items）
      final newHistory = ClipboardHistory(initialItems: sortedHistory);
      await storageService.save(newHistory);

      // Act: 重新加载
      final reloadedHistory = await storageService.load();

      // Assert: 验证置顶项目按置顶时间倒序排列（最后置顶的在最前）
      final pinnedItems = reloadedHistory.items.where((i) => i.pinned).toList();

      expect(pinnedItems.length, equals(3),
        reason: '应该有3个置顶项目');

      expect(pinnedItems[0].id, item3.id,
        reason: '最后置顶的项目应该在最前面');
      expect(pinnedItems[1].id, item2.id,
        reason: '第二后置顶的项目应该在第二位');
      expect(pinnedItems[2].id, item1.id,
        reason: '最先置顶的项目应该在第三位');
    });

    test('应该持久化取消置顶操作（重启后保持未置顶状态）', () async {
      // Arrange: 置顶然后取消置顶
      final item = ClipboardItem(
        id: 'test-item-unpin',
        content: '将被取消置顶的项目',
        type: ClipboardItemType.text,
        category: Category.text,
        timestamp: DateTime.now(),
        hash: 'test-hash-unpin',
        size: 100,
      );

      var history = await storageService.load();
      history = history.add(item);

      // 置顶
      var pinnedItem = pinService.pin(item);
      history = history..remove(item.id);
      history = history.add(pinnedItem);
      await storageService.save(history);

      // 取消置顶
      var reloadedHistory = await storageService.load();
      var foundItem = reloadedHistory.items.firstWhere((i) => i.id == item.id);
      var unpinnedItem = pinService.unpin(foundItem);

      reloadedHistory = reloadedHistory..remove(item.id);
      reloadedHistory = reloadedHistory.add(unpinnedItem);
      await storageService.save(reloadedHistory);

      // Act: 再次重新加载
      final finalHistory = await storageService.load();
      final finalItem = finalHistory.items.firstWhere((i) => i.id == item.id);

      // Assert: 验证取消置顶状态持久化
      expect(finalItem.pinned, isFalse,
        reason: '取消置顶状态应该在重启后保持');
      expect(finalItem.pinnedAt, isNull,
        reason: '取消置顶后置顶时间应该为null');
    });

    test('应该正确处理旧数据格式（向后兼容）', () async {
      // Arrange: 创建没有置顶字段的旧格式数据
      final oldItem = ClipboardItem(
        id: 'old-item',
        content: '旧格式项目',
        type: ClipboardItemType.text,
        category: Category.text,
        timestamp: DateTime.now(),
        hash: 'old-hash',
        size: 100,
        // 没有设置 pinned 和 pinnedAt 字段
      );

      final history = await storageService.load();
      final updatedHistory = history.add(oldItem);
      await storageService.save(updatedHistory);

      // Act: 重新加载
      final reloadedHistory = await storageService.load();
      final reloadedItem = reloadedHistory.items.firstWhere(
        (i) => i.id == oldItem.id,
      );

      // Assert: 验证旧数据能正确加载（默认未置顶）
      expect(reloadedItem.pinned, isFalse,
        reason: '旧格式项目应该默认为未置顶状态');
      expect(reloadedItem.pinnedAt, isNull,
        reason: '旧格式项目的置顶时间应该为null');
    });

    test('应该正确处理置顶项目被删除的情况', () async {
      // Arrange: 置顶一个剪贴板项目
      final item = ClipboardItem(
        id: 'test-item-to-delete',
        content: '将被删除的项目',
        type: ClipboardItemType.text,
        category: Category.text,
        timestamp: DateTime.now(),
        hash: 'test-hash-delete',
        size: 100,
      );

      final history = await storageService.load();
      final updatedHistory = history.add(item);

      // 置顶项目
      final pinnedItem = pinService.pin(item);
      final historyWithPinned = updatedHistory..remove(item.id);
      final finalHistory = historyWithPinned.add(pinnedItem);
      await storageService.save(finalHistory);

      // Act: 删除项目并重新加载
      var reloadedHistory = await storageService.load();
      reloadedHistory = reloadedHistory..remove(item.id);
      await storageService.save(reloadedHistory);

      final finalReloadedHistory = await storageService.load();

      // Assert: 验证项目已被删除且不影响其他项目
      expect(
        finalReloadedHistory.items.any((i) => i.id == item.id),
        isFalse,
        reason: '项目应该已被删除',
      );
    });
  });
}
