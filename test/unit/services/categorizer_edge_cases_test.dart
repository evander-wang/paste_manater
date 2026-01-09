import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/models/category.dart';
import 'package:paste_manager/models/clipboard_item.dart';

void main() {
  group('Categorizer 边界情况测试', () {
    test('应该正确处理包含emoji的文本', () {
      final emojiSamples = [
        ('Hello 😊 world', Category.text),
        ('Check this out 👍 https://example.com', Category.link), // 包含URL的emoji文本
        ('🎉 Party time!', Category.text),
        ('File at /Users/test 📁', Category.file), // 包含文件路径的emoji文本
      ];

      for (final (content, expected) in emojiSamples) {
        final result = CategoryClassifier.classify(content, ClipboardDataType.text);
        expect(
          result,
          expected,
          reason: 'Emoji文本分类错误: "$content" 应该是 $expected',
        );
      }
    });

    test('应该正确处理特殊字符', () {
      final specialCharSamples = [
        ('Text with "quotes" and \'apostrophes\'', Category.text),
        ('Special chars: @#\$%^&*()_+-=[]{}|;:\'",.<>?/', Category.text),
        ('Multiple\n    newlines\nand tabs', Category.text),
        ('Text with <html> tags', Category.text), // 不是代码，只是标签
        ('<div>Not code without braces</div>', Category.text),
        ('https://example.com?param=value&other=测试', Category.link), // URL with Unicode
        ('文件路径/用户/文档/测试.txt', Category.text), // 中文路径（不符合Unix/Windows模式）
      ];

      for (final (content, expected) in specialCharSamples) {
        final result = CategoryClassifier.classify(content, ClipboardDataType.text);
        expect(
          result,
          expected,
          reason: '特殊字符文本分类错误: "$content" 应该是 $expected',
        );
      }
    });

    test('应该正确处理混合内容（优先级匹配）', () {
      final mixedContentSamples = [
        // 优先级: image > link > file > code > text
        ('Visit https://example.com for function hello() { }', Category.link), // URL优先
        ('See code at /path/to/file.js with function test() { }', Category.file), // 路径优先
        ('URL in comment: // https://example.com', Category.link), // 即使在注释中，URL也优先
        ('Text mentioning website.com (not a URL)', Category.text), // 不是真实URL
        ('Copy this: C:\\Users\\username with function() {}', Category.file), // 路径优先
      ];

      for (final (content, expected) in mixedContentSamples) {
        final result = CategoryClassifier.classify(content, ClipboardDataType.text);
        expect(
          result,
          expected,
          reason: '混合内容分类错误: "$content" 应该是 $expected（优先级测试）',
        );
      }
    });

    test('应该正确处理空字符串和空白', () {
      final emptySamples = [
        ('', Category.text),
        ('   ', Category.text),
        ('\n\n\n', Category.text),
        ('\t\t\t', Category.text),
      ];

      for (final (content, expected) in emptySamples) {
        final result = CategoryClassifier.classify(content, ClipboardDataType.text);
        expect(
          result,
          expected,
          reason: '空字符串分类错误: "${content.isEmpty ? '<empty>' : content}" 应该是 $expected',
        );
      }
    });

    test('应该正确处理非常长的内容', () {
      final longText = 'Regular text. ' * 1000;
      final result = CategoryClassifier.classify(longText, ClipboardDataType.text);
      expect(result, Category.text, reason: '长文本应该分类为text');
    });

    test('应该正确处理代码变体', () {
      final codeVariants = [
        // 箭头函数
        ('const add = (a, b) => a + b;', Category.code),
        // 多行代码
        ('''
function test() {
  if (true) {
    return "hello";
  }
}
''', Category.code),
        // 多个代码特征
        ('class MyClass { constructor() { } } and function() {}', Category.code),
        // 带有注释的代码
        ('// This is a comment\nfunction test() { }', Category.code),
        // Python装饰器
        ('@decorator\ndef function():\n    pass', Category.code),
        // 类型定义
        ('interface User { name: string; }', Category.code),
      ];

      for (final (content, expected) in codeVariants) {
        final result = CategoryClassifier.classify(content, ClipboardDataType.text);
        expect(
          result,
          expected,
          reason: '代码变体分类错误: "$content" 应该是 $expected',
        );
      }
    });

    test('应该正确处理路径变体', () {
      final pathVariants = [
        ('~/Documents/file.txt', Category.file),
        ('./relative/path', Category.file),
        ('../parent/path', Category.file),
        ('/absolute/path/to/file', Category.file),
        ('C:\\Windows\\System32', Category.file),
        ('D:\\Data\\file.txt', Category.file),
        ('/usr/local/bin', Category.file),
        ('/etc/config.conf', Category.file),
        ('/var/log/app.log', Category.file),
      ];

      for (final (content, expected) in pathVariants) {
        final result = CategoryClassifier.classify(content, ClipboardDataType.text);
        expect(
          result,
          expected,
          reason: '路径变体分类错误: "$content" 应该是 $expected',
        );
      }
    });

    test('应该正确处理URL变体', () {
      final urlVariants = [
        ('http://example.com', Category.link),
        ('https://example.com', Category.link),
        ('https://subdomain.example.com/path', Category.link),
        ('http://localhost:8080', Category.link),
        ('https://192.168.1.1:3000/api', Category.link),
        ('https://example.com?param=value&other=123', Category.link),
        ('https://example.com#section', Category.link),
        ('HTTPS://EXAMPLE.COM', Category.link), // 大写URL
        ('  https://example.com  ', Category.link), // 带空格的URL
      ];

      for (final (content, expected) in urlVariants) {
        final result = CategoryClassifier.classify(content, ClipboardDataType.text);
        expect(
          result,
          expected,
          reason: 'URL变体分类错误: "$content" 应该是 $expected',
        );
      }
    });

    test('应该正确处理看起来像代码但实际是文本的内容', () {
      final falseCodeSamples = [
        ('Just a single brace {', Category.text), // 只有一个括号特征
        ('Single parenthesis (', Category.text), // 只有一个括号
        ('Text mentioning function but not code', Category.text), // 提到function但不是代码
        ('The word class is here', Category.text), // 提到class但不是代码
        ('Open ( and close ) but not code', Category.text), // 只有一对括号
      ];

      for (final (content, expected) in falseCodeSamples) {
        final result = CategoryClassifier.classify(content, ClipboardDataType.text);
        expect(
          result,
          expected,
          reason: '假代码样本分类错误: "$content" 应该是 $expected',
        );
      }
    });

    test('应该正确处理边界URL格式', () {
      final boundaryUrlSamples = [
        ('http://', Category.text), // 不完整的URL
        ('https://', Category.text), // 不完整的URL
        ('http:// example.com', Category.text), // 有空格的无效URL
        ('texthttp://example.com', Category.text), // 前缀文本
        ('https://example', Category.link), // 最短有效URL
        ('http://a.co', Category.link), // 最短域名
      ];

      for (final (content, expected) in boundaryUrlSamples) {
        final result = CategoryClassifier.classify(content, ClipboardDataType.text);
        expect(
          result,
          expected,
          reason: '边界URL格式分类错误: "$content" 应该是 $expected',
        );
      }
    });
  });
}
