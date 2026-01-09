import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/models/category.dart';
import 'package:paste_manager/models/clipboard_item.dart';
import 'package:paste_manager/models/clipboard_history.dart';
import 'package:paste_manager/models/search_query.dart';
import 'package:paste_manager/services/search_service.dart';

void main() {
  group('搜索性能测试', () {
    late SearchService searchService;
    late ClipboardHistory history;

    setUp(() {
      searchService = SearchService();

      // 创建1000个测试项目
      final items = <ClipboardItem>[];

      // 添加各种类型的内容
      for (int i = 0; i < 1000; i++) {
        final category = i % 5;
        items.add(ClipboardItem(
          id: 'perf-$i',
          content: _generateTestContent(i, category),
          type: ClipboardItemType.text,
          category: _getCategory(category),
          timestamp: DateTime.now().add(Duration(seconds: i)),
          hash: 'perf-hash-$i',
          size: 50 + (i % 100),
        ));
      }

      history = ClipboardHistory(initialItems: items);

      // 构建索引
      searchService.buildIndex(history);
    });

    testWidgets('搜索1000项应该在<300ms内完成（100次查询平均）', (WidgetTester tester) async {
      // Arrange
      final queries = [
        'test',
        'function',
        'https://',
        'search',
        'content',
        'item',
      ];

      final latencies = <Duration>[];
      const testRuns = 100;

      // Act: 执行100次搜索查询
      for (int i = 0; i < testRuns; i++) {
        final query = queries[i % queries.length];

        final stopwatch = Stopwatch()..start();

        final results = searchService.search(
          history,
          SearchQuery(query: query),
        );

        stopwatch.stop();

        latencies.add(stopwatch.elapsed);
      }

      // Assert: 计算平均延迟
      final totalLatency = latencies.fold(
        Duration.zero,
        (sum, duration) => sum + duration,
      );
      final averageLatency = totalLatency ~/ testRuns;

      print('========== 搜索性能报告 ==========');
      print('历史项目数: ${history.totalCount}');
      print('测试次数: $testRuns');
      print('平均延迟: ${averageLatency.inMilliseconds}ms');
      print('最大延迟: ${latencies.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b)}ms');
      print('最小延迟: ${latencies.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b)}ms');
      print('====================================');

      expect(
        averageLatency.inMilliseconds,
        lessThan(300),
        reason: '搜索1000项的平均延迟应该 <300ms',
      );
    });

    testWidgets('分类过滤应该在<100ms内完成', (WidgetTester tester) async {
      // Arrange
      final categories = Category.values;
      final latencies = <Duration>[];

      // Act: 测试每个分类的过滤性能
      for (final category in categories) {
        final stopwatch = Stopwatch()..start();

        final results = searchService.search(
          history,
          SearchQuery(category: category),
        );

        stopwatch.stop();

        latencies.add(stopwatch.elapsed);
      }

      // Assert
      final totalLatency = latencies.fold(
        Duration.zero,
        (sum, duration) => sum + duration,
      );
      final averageLatency = totalLatency ~/ categories.length;

      print('========== 分类过滤性能报告 ==========');
      print('分类数量: ${categories.length}');
      print('平均延迟: ${averageLatency.inMilliseconds}ms');
      print('====================================');

      expect(
        averageLatency.inMilliseconds,
        lessThan(100),
        reason: '分类过滤延迟应该 <100ms',
      );
    });

    testWidgets('组合搜索（关键词+分类）应该在<300ms内完成', (WidgetTester tester) async {
      // Arrange
      final queries = [
        ('test', Category.text),
        ('https://', Category.link),
        ('function', Category.code),
      ];

      final latencies = <Duration>[];

      // Act: 测试组合查询
      for (int i = 0; i < 50; i++) {
        final (query, category) = queries[i % queries.length];

        final stopwatch = Stopwatch()..start();

        final results = searchService.search(
          history,
          SearchQuery(query: query, category: category),
        );

        stopwatch.stop();

        latencies.add(stopwatch.elapsed);
      }

      // Assert
      final totalLatency = latencies.fold(
        Duration.zero,
        (sum, duration) => sum + duration,
      );
      final averageLatency = totalLatency ~/ latencies.length;

      print('========== 组合搜索性能报告 ==========');
      print('测试次数: ${latencies.length}');
      print('平均延迟: ${averageLatency.inMilliseconds}ms');
      print('====================================');

      expect(
        averageLatency.inMilliseconds,
        lessThan(300),
        reason: '组合搜索延迟应该 <300ms',
      );
    });

    testWidgets('索引构建应该在<500ms内完成（1000项）', (WidgetTester tester) async {
      // Arrange
      final newHistory = ClipboardHistory(
        initialItems: List.generate(1000, (i) => ClipboardItem(
          id: 'index-test-$i',
          content: 'Test content $i',
          type: ClipboardItemType.text,
          category: Category.text,
          timestamp: DateTime.now(),
          hash: 'hash-$i',
          size: 50,
        )),
      );

      // Act
      final stopwatch = Stopwatch()..start();

      searchService.buildIndex(newHistory);

      stopwatch.stop();

      // Assert
      print('========== 索引构建性能报告 ==========');
      print('项目数量: 1000');
      print('构建时间: ${stopwatch.elapsedMilliseconds}ms');
      print('====================================');

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500),
        reason: '索引构建应该在<500ms内完成',
      );
    });

    testWidgets('空结果搜索应该快速返回', (WidgetTester tester) async {
      // Arrange
      final stopwatch = Stopwatch()..start();

      // Act: 搜索不存在的关键词
      final results = searchService.search(
        history,
        SearchQuery(query: 'nonexistent_content_xyz123'),
      );

      stopwatch.stop();

      // Assert
      expect(results.isEmpty, isTrue);
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: '空结果搜索应该快速返回',
      );

      print('空结果搜索延迟: ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('长查询字符串应该不影响性能', (WidgetTester tester) async {
      // Arrange: 创建一个很长的查询字符串
      final longQuery = 'test ' * 50; // 250个字符

      final stopwatch = Stopwatch()..start();

      // Act
      final results = searchService.search(
        history,
        SearchQuery(query: longQuery),
      );

      stopwatch.stop();

      // Assert
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(300),
        reason: '长查询字符串不应该显著影响性能',
      );

      print('长查询搜索延迟: ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('内存使用应该保持稳定', (WidgetTester tester) async {
      // Arrange
      final initialResults = searchService.search(
        history,
        SearchQuery(query: 'test'),
      );

      // Act: 执行大量搜索
      for (int i = 0; i < 100; i++) {
        searchService.search(
          history,
          SearchQuery(query: 'test $i'),
        );
      }

      // Assert: 最终搜索应该仍然快速
      final stopwatch = Stopwatch()..start();
      final finalResults = searchService.search(
        history,
        SearchQuery(query: 'test'),
      );
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(300),
        reason: '内存使用应该保持稳定',
      );

      expect(finalResults.length, equals(initialResults.length));
    });
  });

  // 辅助方法

  String _generateTestContent(int index, int category) {
    switch (category) {
      case 0: // text
        return 'Test content number $index with some text';
      case 1: // link
        return 'https://example.com/page/$index';
      case 2: // code
        return 'function test$index() { return $index; }';
      case 3: // file
        return '/Users/username/project/file_$index.txt';
      case 4: // image (作为文本)
        return '[Image data $index]';
      default:
        return 'Content $index';
    }
  }

  Category _getCategory(int index) {
    switch (index) {
      case 0: return Category.text;
      case 1: return Category.link;
      case 2: return Category.code;
      case 3: return Category.file;
      case 4: return Category.image;
      default: return Category.text;
    }
  }
}
