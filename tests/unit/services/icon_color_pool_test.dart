import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/services/icon_color_pool.dart';

void main() {
  group('IconColorPool', () {
    group('getRandomIcon', () {
      test('应该返回有效的IconData', () {
        // Act
        final icon = IconColorPool.getRandomIcon();

        // Assert
        expect(icon, isA<IconData>());
        expect(icon.codePoint, greaterThan(0));
      });

      test('多次调用应该返回不同的图标（大部分情况）', () {
        // Act
        final icons = List.generate(10, (_) => IconColorPool.getRandomIcon());

        // Assert
        final uniqueIcons = icons.toSet();
        // 至少应该有一些不同的图标
        expect(uniqueIcons.length, greaterThan(1));
        // 所有图标都应该在池中
        for (final icon in icons) {
          expect(IconColorPool.getAllIcons(), contains(icon));
        }
      });

      test('返回的图标应该在预定义池中', () {
        // Arrange
        final allIcons = IconColorPool.getAllIcons();

        // Act
        for (int i = 0; i < 20; i++) {
          final icon = IconColorPool.getRandomIcon();

          // Assert
          expect(allIcons, contains(icon));
        }
      });
    });

    group('getRandomColor', () {
      test('应该返回有效的Color', () {
        // Act
        final color = IconColorPool.getRandomColor();

        // Assert
        expect(color, isA<Color>());
        expect(color.value, greaterThan(0));
        expect(color.value, lessThanOrEqualTo(0xFFFFFFFF));
      });

      test('多次调用应该返回不同的颜色（大部分情况）', () {
        // Act
        final colors = List.generate(10, (_) => IconColorPool.getRandomColor());

        // Assert
        final uniqueColors = colors.toSet();
        // 至少应该有一些不同的颜色
        expect(uniqueColors.length, greaterThan(1));
        // 所有颜色都应该在池中
        for (final color in colors) {
          expect(IconColorPool.getAllColors(), contains(color));
        }
      });

      test('返回的颜色应该在预定义池中', () {
        // Arrange
        final allColors = IconColorPool.getAllColors();

        // Act
        for (int i = 0; i < 20; i++) {
          final color = IconColorPool.getRandomColor();

          // Assert
          expect(allColors, contains(color));
        }
      });
    });

    group('getAllIcons', () {
      test('应该返回所有预定义图标', () {
        // Act
        final icons = IconColorPool.getAllIcons();

        // Assert
        expect(icons, isNotEmpty);
        expect(icons.length, IconColorPool.iconCount);
        expect(icons, everyElement(isA<IconData>()));
      });

      test('返回的列表应该是不可变的', () {
        // Act
        final icons = IconColorPool.getAllIcons();

        // Assert
        expect(() => icons.add(Icons.abc), throwsUnsupportedError);
      });
    });

    group('getAllColors', () {
      test('应该返回所有预定义颜色', () {
        // Act
        final colors = IconColorPool.getAllColors();

        // Assert
        expect(colors, isNotEmpty);
        expect(colors.length, IconColorPool.colorCount);
        expect(colors, everyElement(isA<Color>()));
      });

      test('应该包含多种颜色系', () {
        // Act
        final colors = IconColorPool.getAllColors();

        // Assert
        // 应该至少有红色、蓝色、绿色等
        final hasRed = colors.any((c) => c.red > 200 && c.green < 100 && c.blue < 100);
        final hasBlue = colors.any((c) => c.red < 100 && c.green < 100 && c.blue > 200);
        final hasGreen = colors.any((c) => c.red < 100 && c.green > 200 && c.blue < 100);

        expect(hasRed || hasBlue || hasGreen, true);
      });

      test('返回的列表应该是不可变的', () {
        // Act
        final colors = IconColorPool.getAllColors();

        // Assert
        expect(() => colors.add(const Color(0xFF000000)), throwsUnsupportedError);
      });
    });

    group('iconCount', () {
      test('应该返回正确的图标数量', () {
        // Act
        final count = IconColorPool.iconCount;

        // Assert
        expect(count, greaterThan(0));
        expect(count, IconColorPool.getAllIcons().length);
      });
    });

    group('colorCount', () {
      test('应该返回正确的颜色数量', () {
        // Act
        final count = IconColorPool.colorCount;

        // Assert
        expect(count, greaterThan(0));
        expect(count, IconColorPool.getAllColors().length);
      });
    });

    group('图标和颜色池多样性', () {
      test('图标池应该包含至少35个图标', () {
        // Act
        final count = IconColorPool.iconCount;

        // Assert
        expect(count, greaterThanOrEqualTo(35));
      });

      test('颜色池应该包含至少35种颜色', () {
        // Act
        final count = IconColorPool.colorCount;

        // Assert
        expect(count, greaterThanOrEqualTo(35));
      });

      test('图标和颜色应该随机分布', () {
        // Act
        final samples = List.generate(50, (_) {
          return IconColorPool.getRandomIcon().codePoint +
              IconColorPool.getRandomColor().value;
        });

        // Assert
        final uniqueSamples = samples.toSet();
        // 样本应该有一定多样性（不是所有都相同）
        expect(uniqueSamples.length, greaterThan(10));
      });
    });
  });
}
