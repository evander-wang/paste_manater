import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/models/category.dart';
import 'package:paste_manager/models/clipboard_item.dart';

void main() {
  group('Categorizer 准确率测试（100个样本）', () {
    late int correctClassifications;
    late int totalSamples;

    test('应该在100个测试样本上达到≥95%的准确率', () {
      // 测试样本：每个样本包含 (content, expectedCategory)
      final testSamples = <({String content, Category expected})>[
        // URL样本 (20个)
        (content: 'https://www.example.com', expected: Category.link),
        (content: 'http://github.com/user/repo', expected: Category.link),
        (content: 'https://stackoverflow.com/questions/123', expected: Category.link),
        (content: 'https://docs.flutter.dev/get-started', expected: Category.link),
        (content: 'http://localhost:8080/api', expected: Category.link),
        (content: 'https://www.amazon.com/dp/B08X', expected: Category.link),
        (content: 'https://twitter.com/user/status/123', expected: Category.link),
        (content: 'https://youtube.com/watch?v=abc123', expected: Category.link),
        (content: 'https://drive.google.com/file/d/xyz', expected: Category.link),
        (content: 'http://192.168.1.1:3000', expected: Category.link),
        (content: 'https://www.example.com/path/to/page', expected: Category.link),
        (content: 'http://example.com?param=value&other=123', expected: Category.link),
        (content: 'https://api.github.com/repos', expected: Category.link),
        (content: 'http://test.example.com:8080/api/v1', expected: Category.link),
        (content: 'https://subdomain.example.com', expected: Category.link),
        (content: 'http://example.com#section', expected: Category.link),
        (content: 'https://example.com/path?query=test', expected: Category.link),
        (content: 'http://ftp.example.com/file.txt', expected: Category.link),
        (content: 'https://cdn.example.com/image.png', expected: Category.link),
        (content: 'http://localhost:3000', expected: Category.link),

        // 文件路径样本 (20个)
        (content: '/Users/username/Documents/file.txt', expected: Category.file),
        (content: '/home/user/projects/flutter_app', expected: Category.file),
        (content: '/etc/config/settings.conf', expected: Category.file),
        (content: '/var/log/system.log', expected: Category.file),
        (content: 'C:\\Users\\username\\Documents\\file.txt', expected: Category.file),
        (content: 'D:\\Projects\\myapp\\src\\main.dart', expected: Category.file),
        (content: 'C:\\Program Files\\App', expected: Category.file),
        (content: '/usr/local/bin/command', expected: Category.file),
        (content: '~/Desktop/report.pdf', expected: Category.file),
        (content: './relative/path/to/file', expected: Category.file),
        (content: '../parent/directory/file.txt', expected: Category.file),
        (content: '/Volumes/ExternalDrive/file.txt', expected: Category.file),
        (content: 'E:\\Backup\\data.sql', expected: Category.file),
        (content: '/tmp/cache/file.tmp', expected: Category.file),
        (content: '/opt/app/config.yml', expected: Category.file),
        (content: 'C:\\Users\\username\\Downloads', expected: Category.file),
        (content: '/home/user/.bashrc', expected: Category.file),
        (content: '/etc/hosts', expected: Category.file),
        (content: 'D:\\data\\database.sqlite', expected: Category.file),
        (content: '/Users/username/Pictures/photo.jpg', expected: Category.file),

        // 代码样本 (20个)
        (content: 'function calculateSum(a, b) { return a + b; }', expected: Category.code),
        (content: 'class MyClass { constructor() { this.name = "test"; } }', expected: Category.code),
        (content: 'def my_function():\n    return True', expected: Category.code),
        (content: 'public class User {\n    private String name;\n}', expected: Category.code),
        (content: 'const result = await fetch(url);', expected: Category.code),
        (content: 'if (condition) { doSomething(); }', expected: Category.code),
        (content: 'for (let i = 0; i < 10; i++) { console.log(i); }', expected: Category.code),
        (content: 'import { Component } from "@angular/core";', expected: Category.code),
        (content: '@app.route("/api")\ndef api():\n    pass', expected: Category.code),
        (content: 'SELECT * FROM users WHERE id = 1;', expected: Category.code),
        (content: 'interface User { name: string; age: number; }', expected: Category.code),
        (content: 'type Result = Promise<string>;', expected: Category.code),
        (content: 'function hello() { console.log("world"); }', expected: Category.code),
        (content: 'class Test extends Component { }', expected: Category.code),
        (content: '{ "key": "value", "number": 123 }', expected: Category.code),
        (content: '[1, 2, 3].map(x => x * 2)', expected: Category.code),
        (content: 'try { doSomething(); } catch (e) { handleError(e); }', expected: Category.code),
        (content: 'export const PI = 3.14159;', expected: Category.code),
        (content: '# Python function\ndef test():\n    pass', expected: Category.code),
        (content: '<div>Hello World</div>', expected: Category.code),

        // 纯文本样本 (20个)
        (content: 'Hello, this is a simple text message.', expected: Category.text),
        (content: 'Meeting scheduled for tomorrow at 3 PM.', expected: Category.text),
        (content: 'Don\'t forget to buy groceries.', expected: Category.text),
        (content: 'The quick brown fox jumps over the lazy dog.', expected: Category.text),
        (content: 'Phone number: 555-1234', expected: Category.text),
        (content: 'Email: user@example.com', expected: Category.text),
        (content: 'Regular text with some numbers 12345', expected: Category.text),
        (content: 'Just a normal sentence without code.', expected: Category.text),
        (content: 'To-do list:\n1. Item one\n2. Item two', expected: Category.text),
        (content: 'Notes from the meeting:', expected: Category.text),
        (content: 'Remember to call mom later.', expected: Category.text),
        (content: 'This is just plain text with no special patterns.', expected: Category.text),
        (content: 'Quote: "To be or not to be"', expected: Category.text),
        (content: 'Reminder: Dentist appointment on Friday', expected: Category.text),
        (content: 'Shopping list: milk, eggs, bread', expected: Category.text),
        (content: 'Text with emoji 😊 but still plain text', expected: Category.text),
        (content: '123 Main Street, Springfield', expected: Category.text),
        (content: 'Invoice #12345 paid', expected: Category.text),
        (content: 'Temperature today: 72°F', expected: Category.text),
        (content: 'Regular paragraph with multiple sentences. Some more text here.', expected: Category.text),

        // 图像（通过类型检测，不在内容测试中）
        // 图像分类通过 ClipboardDataType.image 处理
      ];

      // 运行分类
      correctClassifications = 0;
      totalSamples = testSamples.length;

      for (final sample in testSamples) {
        final result = CategoryClassifier.classify(
          sample.content,
          ClipboardDataType.text,
        );

        if (result == sample.expected) {
          correctClassifications++;
        } else {
          print(
            '分类错误: "${sample.content}"\n'
            '  期望: ${sample.expected.name}\n'
            '  实际: ${result.name}',
          );
        }
      }

      // 计算准确率
      final accuracy = correctClassifications / totalSamples;

      print('\n========== 分类准确率报告 ==========');
      print('总样本数: $totalSamples');
      print('正确分类: $correctClassifications');
      print('错误分类: ${totalSamples - correctClassifications}');
      print('准确率: ${(accuracy * 100).toStringAsFixed(1)}%');
      print('====================================\n');

      // 断言：准确率应该 ≥95%
      expect(
        accuracy,
        greaterThanOrEqualTo(0.95),
        reason: '分类准确率应该 ≥95%，当前为 ${(accuracy * 100).toStringAsFixed(1)}%',
      );
    });
  });

  group('分类器性能测试', () {
    test('分类1000个项目应该在合理时间内完成（<100ms）', () {
      final content = 'function test() { return "hello"; }';

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        CategoryClassifier.classify(content, ClipboardDataType.text);
      }

      stopwatch.stop();

      print('分类1000个项目耗时: ${stopwatch.elapsedMilliseconds}ms');

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: '分类1000个项目应该在100ms内完成',
      );
    });
  });
}
