import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/models/custom_category.dart';

void main() {
  group('CustomCategory', () {
    group('序列化/反序列化', () {
      test('应该正确序列化为JSON', () {
        // Arrange
        final category = CustomCategory(
          id: 'custom_1234567890',
          name: '工作',
          icon: Icons.work,
          color: Color(0xFF2196F3),
          createdAt: DateTime(2026, 1, 16, 10, 30),
        );

        // Act
        final json = category.toJson();

        // Assert
        expect(json['id'], 'custom_1234567890');
        expect(json['name'], '工作');
        expect(json['icon'], '59122'); // Icons.work codePoint (十进制)
        expect(json['color'], 'ff2196f3');
        expect(json['createdAt'], '2026-01-16T10:30:00.000');
      });

      test('应该正确从JSON反序列化', () {
        // Arrange
        final json = {
          'id': 'custom_1234567890',
          'name': '工作',
          'icon': '59122', // Icons.work codePoint (实际值)
          'color': 'ff2196f3',
          'createdAt': '2026-01-16T10:30:00.000',
        };

        // Act
        final category = CustomCategory.fromJson(json);

        // Assert
        expect(category.id, 'custom_1234567890');
        expect(category.name, '工作');
        expect(category.iconCodePoint, 59122); // Icons.work的实际codePoint
        expect(category.color.value, 0xFF2196F3);
        expect(category.createdAt, DateTime(2026, 1, 16, 10, 30));
      });

      test('序列化和反序列化应该保持数据完整性', () {
        // Arrange
        final original = CustomCategory(
          id: 'custom_9876543210',
          name: '个人项目',
          icon: Icons.star,
          color: Color(0xFFFF9800),
          createdAt: DateTime(2026, 1, 16, 12, 0),
        );

        // Act
        final json = original.toJson();
        final restored = CustomCategory.fromJson(json);

        // Assert
        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.iconCodePoint, original.iconCodePoint);
        expect(restored.color.value, original.color.value);
        expect(restored.createdAt, original.createdAt);
      });

      test('应该支持Unicode名称（emoji）', () {
        // Arrange
        final category = CustomCategory(
          id: 'custom_emoji',
          name: '🎨设计',
          icon: Icons.palette,
          color: Color(0xFFE91E63),
          createdAt: DateTime.now(),
        );

        // Act
        final json = category.toJson();
        final restored = CustomCategory.fromJson(json);

        // Assert
        expect(restored.name, '🎨设计');
      });

      test('应该正确处理最大长度名称（10字符）', () {
        // Arrange
        final longName = '1234567890'; // 10个字符
        final category = CustomCategory(
          id: 'custom_long',
          name: longName,
          icon: Icons.label,
          color: Color(0xFF4CAF50),
          createdAt: DateTime.now(),
        );

        // Act
        final json = category.toJson();
        final restored = CustomCategory.fromJson(json);

        // Assert
        expect(restored.name, longName);
        expect(restored.name.length, 10);
      });
    });

    group('toString', () {
      test('应该返回包含ID和名称的字符串', () {
        // Arrange
        final category = CustomCategory(
          id: 'custom_test',
          name: '测试分类',
          icon: Icons.category,
          color: Color(0xFF9C27B0),
          createdAt: DateTime.now(),
        );

        // Act
        final str = category.toString();

        // Assert
        expect(str, contains('custom_test'));
        expect(str, contains('测试分类'));
        expect(str, contains('CustomCategory'));
      });
    });
  });
}
