import 'package:flutter/material.dart';

/// 图标和颜色池工具类
/// 为自定义分类提供预定义的图标和颜色选项
class IconColorPool {
  /// 预定义图标池（Material Icons）
  static const List<IconData> _iconPool = [
    // 工作相关
    Icons.work,
    Icons.business,
    Icons.assignment,
    Icons.folder,
    Icons.folder_open,

    // 标签相关
    Icons.label,
    Icons.bookmark,
    Icons.tag,
    Icons.local_offer,

    // 星形和收藏
    Icons.star,
    Icons.star_border,
    Icons.favorite,
    Icons.favorite_border,

    // 生活相关
    Icons.home,
    Icons.shopping_cart,
    Icons.restaurant,
    Icons.local_cafe,
    Icons.flight,
    Icons.car_rental,

    // 时间相关
    Icons.schedule,
    Icons.access_time,
    Icons.today,
    Icons.event,

    // 通信相关
    Icons.email,
    Icons.phone,
    Icons.chat,
    Icons.contact_mail,

    // 文档相关
    Icons.description,
    Icons.note,
    Icons.article,
    Icons.notes,

    // 其他常用图标
    Icons.dashboard,
    Icons.apps,
    Icons.grid_view,
    Icons.view_list,
    Icons.category,
  ];

  /// 预定义颜色池（Material Design 颜色）
  static const List<Color> _colorPool = [
    // 红色系
    Color(0xFFF44336), // Red
    Color(0xFFE57373), // Red 300
    Color(0xFFFFCDD2), // Red 100

    // 粉色系
    Color(0xFFE91E63), // Pink
    Color(0xFFF06292), // Pink 300
    Color(0xFFF8BBD0), // Pink 100

    // 紫色系
    Color(0xFF9C27B0), // Purple
    Color(0xFFBA68C8), // Purple 300
    Color(0xFFE1BEE7), // Purple 100

    // 深紫色系
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF9575CD), // Deep Purple 300
    Color(0xFFD1C4E9), // Deep Purple 100

    // 靛蓝色系
    Color(0xFF3F51B5), // Indigo
    Color(0xFF7986CB), // Indigo 300
    Color(0xFFC5CAE9), // Indigo 100

    // 蓝色系
    Color(0xFF2196F3), // Blue
    Color(0xFF64B5F6), // Blue 300
    Color(0xFFBBDEFB), // Blue 100

    // 青色系
    Color(0xFF00BCD4), // Cyan
    Color(0xFF4DD0E1), // Cyan 300
    Color(0xFFB2EBF2), // Cyan 100

    // 蓝绿色系
    Color(0xFF009688), // Teal
    Color(0xFF4DB6AC), // Teal 300
    Color(0xFFB2DFDB), // Teal 100

    // 绿色系
    Color(0xFF4CAF50), // Green
    Color(0xFF81C784), // Green 300
    Color(0xFFC8E6C9), // Green 100

    // 橙色系
    Color(0xFFFF9800), // Orange
    Color(0xFFFFB74D), // Orange 300
    Color(0xFFFFE0B2), // Orange 100

    // 琥珀色系
    Color(0xFFFFC107), // Amber
    Color(0xFFFFD54F), // Amber 300
    Color(0xFFFFECB3), // Amber 100

    // 黄色系
    Color(0xFFFFEB3B), // Yellow
    Color(0xFFFFF176), // Yellow 300
    Color(0xFFFFF9C4), // Yellow 100
  ];

  /// 获取随机图标
  ///
  /// Returns: IconData 随机选择的图标
  static IconData getRandomIcon() {
    return _iconPool[(DateTime.now().millisecondsSinceEpoch + _randomSeed()) % _iconPool.length];
  }

  /// 获取随机颜色
  ///
  /// Returns: Color 随机选择的颜色
  static Color getRandomColor() {
    return _colorPool[(DateTime.now().millisecondsSinceEpoch + _randomSeed() + 1) % _colorPool.length];
  }

  /// 获取所有可用图标（用于测试或预览）
  static List<IconData> getAllIcons() => List.unmodifiable(_iconPool);

  /// 获取所有可用颜色（用于测试或预览）
  static List<Color> getAllColors() => List.unmodifiable(_colorPool);

  /// 获取图标池大小
  static int get iconCount => _iconPool.length;

  /// 获取颜色池大小
  static int get colorCount => _colorPool.length;

  /// 生成简单的随机种子
  static int _randomSeed() {
    return DateTime.now().microsecond;
  }
}
