import '../models/pin_status.dart';
import '../models/clipboard_item.dart' show ClipboardItem;

/// 置顶服务
///
/// 提供置顶/取消置顶功能和排序功能
class PinService {
  /// 置顶项目
  ///
  /// 返回新的项目实例,其中pinned=true, pinnedAt=当前时间
  T pin<T extends PinStatus>(T item) {
    // 使用copyWith模式创建新实例
    if (item is ClipboardItem) {
      return item.copyWith(
        pinned: true,
        pinnedAt: DateTime.now(),
      ) as T;
    }
    throw ArgumentError('Unsupported type: ${item.runtimeType}');
  }

  /// 取消置顶
  ///
  /// 返回新的项目实例,其中pinned=false, pinnedAt=null
  T unpin<T extends PinStatus>(T item) {
    if (item is ClipboardItem) {
      return item.copyWith(
        pinned: false,
        clearPinnedAt: true,
      ) as T;
    }
    throw ArgumentError('Unsupported type: ${item.runtimeType}');
  }

  /// 按置顶状态排序
  ///
  /// 置顶项目显示在前面,按置顶时间倒序排列(最近置顶的在前)
  /// 非置顶项目保持原有顺序
  List<T> sortByPinStatus<T extends PinStatus>(List<T> items) {
    // 分离置顶和非置顶项目
    final pinnedItems = <T>[];
    final unpinnedItems = <T>[];

    for (final item in items) {
      if (item.isPinned) {
        pinnedItems.add(item);
      } else {
        unpinnedItems.add(item);
      }
    }

    // 置顶项目按pinnedAt降序排序(最近置顶的在前)
    pinnedItems.sort((a, b) {
      if (a.pinnedAt == null || b.pinnedAt == null) {
        return 0;
      }
      return b.pinnedAt!.compareTo(a.pinnedAt!);
    });

    // 合并:置顶在前 + 非置顶在后
    return [...pinnedItems, ...unpinnedItems];
  }
}
