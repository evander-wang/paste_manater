import 'package:flutter/material.dart';

/// 自定义分类模型
/// 表示用户创建的个性化剪切板分类
class CustomCategory {
  final String id;
  final String name;
  final int iconCodePoint;
  final Color color;
  final DateTime createdAt;

  /// 公共构造函数 - 接受 IconData
  CustomCategory({
    required this.id,
    required this.name,
    required IconData icon,
    required this.color,
    required this.createdAt,
  }) : iconCodePoint = icon.codePoint;

  /// 私有构造函数 - 直接接受 codePoint（用于反序列化）
  CustomCategory._fromCodePoint({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.color,
    required this.createdAt,
  });

  /// 从JSON创建CustomCategory实例
  factory CustomCategory.fromJson(Map<String, dynamic> json) {
    return CustomCategory._fromCodePoint(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCodePoint: int.parse(json['icon'] as String),
      color: Color(int.parse(json['color'] as String, radix: 16)),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// 将CustomCategory转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': iconCodePoint.toString(),
      'color': color.value.toRadixString(16),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'CustomCategory(id: $id, name: $name)';
}
