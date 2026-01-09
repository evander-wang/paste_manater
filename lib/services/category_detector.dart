import '../models/category.dart';

/// 智能内容分类检测器
///
/// 使用模式匹配识别内容类型：链接 > 文件路径 > 代码 > 文本
class CategoryDetector {
  // 链接检测正则（编译时常量优化）
  static final RegExp _linkPattern = RegExp(r'^(https?://|www\.)', caseSensitive: false);

  // 文件路径检测正则
  static final RegExp _filePathPattern = RegExp(r'^[/~]|[A-Z]:\\');

  // 代码关键字检测正则
  static final RegExp _codeKeywordPattern = RegExp(
    r'\b(function|class|def|import|const|let|var|if|for|while|return)\b',
    caseSensitive: false,
  );

  // 代码缩进检测正则
  static final RegExp _codeIndentPattern = RegExp(r'\n\s{2,}');

  /// 检测内容分类
  ///
  /// 返回分类结果，优先级：link > file > code > text
  static Category detect(String content) {
    // 1. 链接检测（优先级 1）
    if (isLink(content)) return Category.link;

    // 2. 文件路径检测（优先级 2）
    if (isFilePath(content)) return Category.file;

    // 3. 代码检测（优先级 3）
    if (isCode(content)) return Category.code;

    // 4. 默认文本（优先级 4）
    return Category.text;
  }

  /// 判断是否为链接
  static bool isLink(String content) {
    return _linkPattern.hasMatch(content.trim());
  }

  /// 判断是否为文件路径
  static bool isFilePath(String content) {
    return _filePathPattern.hasMatch(content.trim());
  }

  /// 判断是否为代码
  static bool isCode(String content) {
    // 检测多行缩进
    final hasIndentation = _codeIndentPattern.hasMatch(content);

    // 检测关键字
    final hasKeywords = _codeKeywordPattern.hasMatch(content);

    return hasIndentation || hasKeywords;
  }
}
