import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/models/command.dart';

void main() {
  group('Command模型字段验证', () {
    test('应该接受有效的name和command', () {
      final command = Command(
        id: 'test-1',
        name: '测试命令',
        command: 'echo "hello"',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      expect(command.id, 'test-1');
      expect(command.name, '测试命令');
      expect(command.command, 'echo "hello"');
      expect(command.pinned, false);
      expect(command.pinnedAt, null);
    });

    test('应该拒绝空name', () {
      expect(
        () => Command(
          id: 'test-1',
          name: '',
          command: 'echo "hello"',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        ).validate(),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('name'),
        )),
      );
    });

    test('应该拒绝超过100字符的name', () {
      expect(
        () => Command(
          id: 'test-1',
          name: 'a' * 101,
          command: 'echo "hello"',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        ).validate(),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('name'),
        )),
      );
    });

    test('应该拒绝空command', () {
      expect(
        () => Command(
          id: 'test-1',
          name: '测试命令',
          command: '',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        ).validate(),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('command'),
        )),
      );
    });

    test('应该拒绝超过10000字符的command', () {
      expect(
        () => Command(
          id: 'test-1',
          name: '测试命令',
          command: 'a' * 10001,
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        ).validate(),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('command'),
        )),
      );
    });

    test('应该接受边界值: 1字符name和100字符name', () {
      final cmd1 = Command(
        id: 'test-1',
        name: 'a',
        command: 'echo "hello"',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      cmd1.validate(); // 不应该抛出异常

      final cmd2 = Command(
        id: 'test-2',
        name: 'a' * 100,
        command: 'echo "hello"',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      cmd2.validate(); // 不应该抛出异常

      expect(cmd1.name.length, 1);
      expect(cmd2.name.length, 100);
    });

    test('应该接受边界值: 1字符command和10000字符command', () {
      final cmd1 = Command(
        id: 'test-1',
        name: '测试命令',
        command: 'a',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      cmd1.validate(); // 不应该抛出异常

      final cmd2 = Command(
        id: 'test-2',
        name: '测试命令',
        command: 'a' * 10000,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      cmd2.validate(); // 不应该抛出异常

      expect(cmd1.command.length, 1);
      expect(cmd2.command.length, 10000);
    });
  });
}
