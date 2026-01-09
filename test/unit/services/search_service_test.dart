import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/models/clipboard_history.dart';
import 'package:paste_manager/models/clipboard_item.dart';
import 'package:paste_manager/models/search_query.dart';
import 'package:paste_manager/models/category.dart';
import 'package:paste_manager/services/search_service.dart';

void main() {
  group('SearchService', () {
    late SearchService searchService;
    late ClipboardHistory history;

    setUp(() {
      searchService = SearchService();

      // 创建测试历史
      final items = [
        _createTestItem('id1', 'Hello World', Category.text),
        _createTestItem('id2', 'https://example.com', Category.link),
        _createTestItem('id3', 'function test() {}', Category.code),
        _createTestItem('id4', 'Goodbye World', Category.text),
        _createTestItem('id5', '/Users/test/file.txt', Category.file),
      ];

      history = ClipboardHistory(initialItems: items);
      searchService.buildIndex(history);
    });

    test('应该正确构建索引', () {
      // Assert
      expect(searchService.getCategoryStats()[Category.text], equals(2));
      expect(searchService.getCategoryStats()[Category.link], equals(1));
      expect(searchService.getCategoryStats()[Category.code], equals(1));
      expect(searchService.getCategoryStats()[Category.file], equals(1));
    });

    test('应该通过哈希快速查找项目', () {
      // Arrange
      final targetItem = history.items[0];

      // Act
      final found = searchService.findByHash(targetItem.hash);

      // Assert
      expect(found, isNotNull);
      expect(found!.id, equals(targetItem.id));
    });

    test('应该正确执行关键词搜索', () {
      // Arrange
      final query = SearchQuery(query: 'World');

      // Act
      final results = searchService.search(history, query);

      // Assert
      expect(results.length, equals(2)); // 'Hello World' 和 'Goodbye World'
      expect(results.any((item) => item.id == 'id1'), isTrue);
      expect(results.any((item) => item.id == 'id4'), isTrue);
    });

    test('应该不区分大小写', () {
      // Arrange
      final query1 = SearchQuery(query: 'hello');
      final query2 = SearchQuery(query: 'HELLO');
      final query3 = SearchQuery(query: 'HeLLo');

      // Act
      final results1 = searchService.search(history, query1);
      final results2 = searchService.search(history, query2);
      final results3 = searchService.search(history, query3);

      // Assert
      expect(results1.length, equals(1));
      expect(results2.length, equals(1));
      expect(results3.length, equals(1));
      expect(results1[0].id, equals('id1'));
      expect(results2[0].id, equals('id1'));
      expect(results3[0].id, equals('id1'));
    });

    test('应该正确执行分类过滤', () {
      // Arrange
      final query = SearchQuery(query: '', category: Category.text);

      // Act
      final results = searchService.search(history, query);

      // Assert
      expect(results.length, equals(2));
      expect(results.every((item) => item.category == Category.text), isTrue);
    });

    test('应该正确组合关键词搜索和分类过滤', () {
      // Arrange
      final query = SearchQuery(query: 'World', category: Category.text);

      // Act
      final results = searchService.search(history, query);

      // Assert
      expect(results.length, equals(2)); // 2 个包含 'World' 的文本项目
      expect(results.every((item) => item.category == Category.text), isTrue);
    });

    test('应该正确处理空查询', () {
      // Arrange
      final query = SearchQuery.empty();

      // Act
      final results = searchService.search(history, query);

      // Assert
      expect(results.length, equals(history.totalCount));
    });

    test('应该返回空结果当搜索无匹配内容时', () {
      // Arrange
      final query = SearchQuery(query: 'nonexistent');

      // Act
      final results = searchService.search(history, query);

      // Assert
      expect(results, isEmpty);
    });

    test('应该正确执行时间范围过滤', () {
      // Arrange
      final startTime = DateTime(2025, 1, 7, 12, 0, 0);
      final endTime = DateTime(2025, 1, 7, 12, 0, 10);
      final query = SearchQuery(
        query: '',
        startTime: startTime,
        endTime: endTime,
      );

      // Act
      final results = searchService.search(history, query);

      // Assert
      // 根据项目的 timestamp，应该只返回范围内的项目
      expect(results.isNotEmpty, isTrue);
      expect(
        results.every((item) =>
          !item.timestamp.isBefore(startTime) &&
          !item.timestamp.isAfter(endTime)),
        isTrue,
      );
    });

    test('应该正确清空索引', () {
      // Act
      searchService.clear();

      // Assert
      expect(searchService.getCategoryStats(), isEmpty);
    });
  });
}

ClipboardItem _createTestItem(
  String id,
  String content,
  Category category,
) {
  return ClipboardItem(
    id: id,
    content: content,
    type: ClipboardItemType.text,
    category: category,
    timestamp: DateTime(2025, 1, 7, 12, 0, 0),
    hash: 'hash_$id',
    size: content.length,
  );
}
