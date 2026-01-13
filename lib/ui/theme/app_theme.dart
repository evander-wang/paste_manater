import 'package:flutter/material.dart';

/// 现代化应用主题
///
/// macOS Big Sur 风格的高端设计主题
class AppTheme {
  /// 亮色主题
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F7), // 浅灰背景

      // 配色方案 - 使用现代渐变色
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF007AFF), // iOS 蓝
        secondary: Color(0xFF5856D6), // iOS 紫色
        tertiary: Color(0xFF32ADE6), // iOS 青色
        surface: Colors.white,
        error: Color(0xFFFF3B30),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1C1C1E),
      ),

      // 卡片主题
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        color: Colors.white,
      ),

      // AppBar 主题
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1C1C1E),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1C1C1E),
        ),
      ),

      // TabBar 主题
      tabBarTheme: const TabBarThemeData(
        labelColor: Color(0xFF007AFF),
        unselectedLabelColor: Color(0xFF8E8E93),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // 浮动按钮主题
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF007AFF),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Chip 主题
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF2F2F7),
        selectedColor: const Color(0xFF007AFF),
        labelStyle: const TextStyle(
          color: Color(0xFF1C1C1E),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
      ),

      // 字体
      fontFamily: '.SF Pro Text',
    );
  }

  /// 深色主题
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF000000), // 纯黑背景

      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF0A84FF), // iOS 深色模式蓝
        secondary: Color(0xFF5E5CE6), // iOS 紫色
        tertiary: Color(0xFF64D2FF), // iOS 青色
        surface: Color(0xFF1C1C1E),
        error: Color(0xFFFF453A),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),

      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        color: Color(0xFF2C2C2E),
      ),

      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor: Color(0xFF0A84FF),
        unselectedLabelColor: Color(0xFF8E8E93),
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF0A84FF),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2C2C2E),
        selectedColor: const Color(0xFF0A84FF),
        labelStyle: const TextStyle(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
      ),

      fontFamily: '.SF Pro Text',
    );
  }
}
