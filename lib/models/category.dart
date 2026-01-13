import 'clipboard_item.dart';

/// 内容分类枚举
///
/// 表示剪贴板内容的分类类型，包含 5 种分类
enum Category {
  text,
  link,
  code,
  file,
  image,
}

/// 分类工具类
///
/// 提供基于内容类型的自动分类功能
class CategoryClassifier {
  /// 根据内容和类型自动分类
  ///
  /// 使用优先级匹配策略：
  /// 1. URL（优先级 1）
  /// 2. 文件路径（优先级 2）
  /// 3. 代码（优先级 3）
  /// 4. 文本（默认，优先级 4）
  static Category classify(String content, ClipboardDataType type) {
    // 优先级 1: URL（http/https）
    if (_isUrl(content)) {
      return Category.link;
    }

    // 优先级 2: 文件路径
    if (_isFilePath(content)) {
      return Category.file;
    }

    // 优先级 3: 代码
    if (_isCode(content)) {
      return Category.code;
    }

    // 默认: 文本
    return Category.text;
  }

  /// 检测是否为 URL（http/https）
  static bool _isUrl(String content) {
    final urlPattern = RegExp(r'^https?://\S+', caseSensitive: false);
    return urlPattern.hasMatch(content.trim());
  }

  /// 检测是否为文件路径
  static bool _isFilePath(String content) {
    // Unix 路径：/Users/...
    final unixPathPattern = RegExp(r'^/[\w\-./]+');
    // Windows 路径：C:\...
    final windowsPathPattern = RegExp(r'^[A-Za-z]:\\[\w\\./-]+');

    return unixPathPattern.hasMatch(content.trim()) ||
        windowsPathPattern.hasMatch(content.trim());
  }

  /// 检测是否为代码
  ///
  /// 通过检测编程语法特征（函数定义、类定义、括号等）
  static bool _isCode(String content) {
    final codeIndicators = [
      // JavaScript 函数定义
      RegExp(r'function\s+\w+\s*\(', caseSensitive: false),
      // Python 函数定义
      RegExp(r'def\s+\w+\s*\(', caseSensitive: false),
      // 类定义
      RegExp(r'class\s+\w+', caseSensitive: false),
      // 大量括号（代码特征）
      RegExp(r'[{}();]'),
    ];

    // 至少匹配 2 个代码特征才认为是代码
    int matchCount = 0;
    for (final pattern in codeIndicators) {
      if (pattern.hasMatch(content)) {
        matchCount++;
      }
    }

    return matchCount >= 2;
  }

  /// 获取分类的显示名称（中文）
  static String getDisplayName(Category category) {
    switch (category) {
      case Category.text:
        return '文本';
      case Category.link:
        return '链接';
      case Category.code:
        return '代码';
      case Category.file:
        return '文件';
      case Category.image:
        return '图像';
    }
  }

  /// 获取分类对应的 SF Symbols 图标名称
  static String getIconName(Category category) {
    switch (category) {
      case Category.text:
        return 'doc.text';
      case Category.link:
        return 'link';
      case Category.code:
        return 'chevron.left.forwardslash.chevron.right';
      case Category.file:
        return 'doc';
      case Category.image:
        return 'photo';
    }
  }

  /// 获取分类的优先级（数字越小优先级越高）
  static int getPriority(Category category) {
    switch (category) {
      case Category.link:
        return 1;
      case Category.file:
        return 2;
      case Category.code:
        return 3;
      case Category.text:
        return 4;
      case Category.image:
        return 5;
    }
  }
}

/// 剪贴板数据类型（用于分类判断）
enum ClipboardDataType {
  text,
  image,
}
