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

  @override
  String get id => category.name;

  @override
  String get displayName => _getLocalizedDisplayName(category);

  @override
  IconData get icon => _getIconFor(category);

  @override
  Color get color => _getColorFor(category);

  @override
  bool get isPreset => true;

  String _getLocalizedDisplayName(Category category) {
    switch (category) {
      case Category.text:
        return '文本';
      case Category.link:
        return '链接';
      case Category.code:
        return '代码';
      case Category.file:
        return '文件';
    }
  }

  IconData _getIconFor(Category category) {
    switch (category) {
      case Category.text:
        return Icons.text_snippet;
      case Category.link:
        return Icons.link;
      case Category.code:
        return Icons.code;
      case Category.file:
        return Icons.insert_drive_file;
    }
  }

  Color _getColorFor(Category category) {
    switch (category) {
      case Category.text:
        return Colors.blueGrey;
      case Category.link:
        return Colors.blue;
      case Category.code:
        return Colors.green;
      case Category.file:
        return Colors.orange;
    }
  }
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
