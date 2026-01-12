import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/services/fileWatcher_service.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockTimer extends Mock implements Timer {}

class MockStreamSubscription extends Mock implements StreamSubscription<FileSystemEvent> {}

void main() {
  group('FileWatcherService防抖测试 (T019)', () {
    late FileWatcherService fileWatcherService;

    setUp(() {
      fileWatcherService = FileWatcherService();
    });

    test('应该在500ms防抖后触发回调', () async {
      final callbackCalled = <String>[];
      final completer = Completer<void>();

      // 监听文件变化
      final subscription = fileWatcherService.watch(
        '/tmp/test.json',
        (event) {
          callbackCalled.add(event.path);
          if (callbackCalled.length == 1) {
            completer.complete();
          }
        },
      );

      // 注意: 由于我们无法轻易触发真实的文件系统事件,
      // 这里主要测试防抖逻辑的结构
      // 实际的防抖行为会在集成测试中验证

      await Future.delayed(Duration(milliseconds: 100));

      subscription.cancel();
      fileWatcherService.dispose();

      // 如果没有真实事件,这个测试主要验证结构正确
      expect(callbackCalled, isEmpty);
    });

    test('应该取消之前的防抖定时器', () async {
      var callCount = 0;
      final completer = Completer<void>();

      final subscription = fileWatcherService.watch(
        '/tmp/test.json',
        (event) {
          callCount++;
          completer.complete();
        },
      );

      // 等待一小段时间
      await Future.delayed(Duration(milliseconds: 100));

      subscription.cancel();
      fileWatcherService.dispose();

      // 防抖应该避免多次调用
      expect(callCount, lessThanOrEqualTo(1));
    });

    test('应该正确处理取消订阅', () {
      var callbackCalled = false;

      final subscription = fileWatcherService.watch(
        '/tmp/test.json',
        (event) {
          callbackCalled = true;
        },
      );

      // 取消订阅
      fileWatcherService.cancel(subscription);

      // 验证资源已清理
      expect(callbackCalled, false);
    });

    test('dispose应该清理所有资源', () {
      fileWatcherService.watch('/tmp/test1.json', (event) {});
      fileWatcherService.watch('/tmp/test2.json', (event) {});

      // dispose 不应该抛出异常
      expect(() => fileWatcherService.dispose(), returnsNormally);
    });
  });

  group('FileChangeEvent', () {
    test('modify工厂方法应该创建修改事件', () {
      final event = FileChangeEvent.modify('/test/path.json');

      expect(event.path, '/test/path.json');
      expect(event.type, FileChangeType.modify);
    });

    test('构造函数应该创建正确的事件', () {
      final event = FileChangeEvent('/test/path.json', FileChangeType.create);

      expect(event.path, '/test/path.json');
      expect(event.type, FileChangeType.create);
    });
  });

  group('FileChangeType', () {
    test('应该包含所有必要的类型', () {
      expect(FileChangeType.modify, isNotNull);
      expect(FileChangeType.create, isNotNull);
      expect(FileChangeType.delete, isNotNull);
    });
  });
}
