import 'package:flutter/material.dart';
import 'custom_category.dart';
import 'category.dart';

/// 统一分类接口
/// 提供预置分类和自定义分类的统一访问接口
abstract class CategoryBase {
  String get id;
  String get displayName;
  IconData get icon;
  Color get color;
  bool get isPreset;
}

/// 预置分类适配器
class PresetCategoryAdapter extends CategoryBase {
  final Category category;

  PresetCategoryAdapter(this.category);

  /// 预置分类属性映射
  static const Map<Category, ({String displayName, IconData icon, Color color})> _categoryProps = {
    Category.text: (displayName: '文本', icon: Icons.text_snippet, color: Colors.blueGrey),
    Category.link: (displayName: '链接', icon: Icons.link, color: Colors.blue),
    Category.code: (displayName: '代码', icon: Icons.code, color: Colors.green),
    Category.file: (displayName: '文件', icon: Icons.insert_drive_file, color: Colors.orange),
  };

  @override
  String get id => category.name;

  @override
  String get displayName => _categoryProps[category]?.displayName ?? category.name;

  @override
  IconData get icon => _categoryProps[category]?.icon ?? Icons.text_snippet;

  @override
  Color get color => _categoryProps[category]?.color ?? Colors.blueGrey;

  @override
  bool get isPreset => true;
}

/// 自定义分类适配器
class CustomCategoryAdapter extends CategoryBase {
  final CustomCategory category;

  CustomCategoryAdapter(this.category);

  @override
  String get id => category.id;

  @override
  String get displayName => category.name;

  @override
  IconData get icon => IconData(category.iconCodePoint, fontFamily: 'MaterialIcons');

  @override
  Color get color => category.color;

  @override
  bool get isPreset => false;
}
