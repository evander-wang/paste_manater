import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/models/command.dart';

void main() {
  group('Command模型序列化', () {
    test('应该正确序列化为JSON', () {
      final now = DateTime.parse('2026-01-12T10:00:00.000Z');
      final command = Command(
        id: 'test-1',
        name: '测试命令',
        command: 'echo "hello"',
        createdAt: now,
        modifiedAt: now,
        pinned: true,
        pinnedAt: now,
      );

      final json = command.toJson();

      expect(json['id'], 'test-1');
      expect(json['name'], '测试命令');
      expect(json['command'], 'echo "hello"');
      expect(json['createdAt'], '2026-01-12T10:00:00.000Z');
      expect(json['modifiedAt'], '2026-01-12T10:00:00.000Z');
      expect(json['pinned'], true);
      expect(json['pinnedAt'], '2026-01-12T10:00:00.000Z');
    });

    test('应该正确从JSON反序列化', () {
      final json = {
        'id': 'test-1',
        'name': '测试命令',
        'command': 'echo "hello"',
        'createdAt': '2026-01-12T10:00:00.000Z',
        'modifiedAt': '2026-01-12T10:00:00.000Z',
        'pinned': true,
        'pinnedAt': '2026-01-12T10:00:00.000Z',
      };

      final command = Command.fromJson(json);

      expect(command.id, 'test-1');
      expect(command.name, '测试命令');
      expect(command.command, 'echo "hello"');
      expect(command.createdAt, DateTime.parse('2026-01-12T10:00:00.000Z'));
      expect(command.modifiedAt, DateTime.parse('2026-01-12T10:00:00.000Z'));
      expect(command.pinned, true);
      expect(command.pinnedAt, DateTime.parse('2026-01-12T10:00:00.000Z'));
    });

    test('应该向后兼容:缺少pinned字段时默认为false', () {
      final json = {
        'id': 'test-1',
        'name': '测试命令',
        'command': 'echo "hello"',
        'createdAt': '2026-01-12T10:00:00.000Z',
        'modifiedAt': '2026-01-12T10:00:00.000Z',
        // 缺少 pinned 和 pinnedAt 字段
      };

      final command = Command.fromJson(json);

      expect(command.id, 'test-1');
      expect(command.pinned, false);
      expect(command.pinnedAt, null);
    });

    test('应该向后兼容:缺少pinnedAt字段时为null', () {
      final json = {
        'id': 'test-1',
        'name': '测试命令',
        'command': 'echo "hello"',
        'createdAt': '2026-01-12T10:00:00.000Z',
        'modifiedAt': '2026-01-12T10:00:00.000Z',
        'pinned': false,
        // 缺少 pinnedAt 字段
      };

      final command = Command.fromJson(json);

      expect(command.pinned, false);
      expect(command.pinnedAt, null);
    });

    test('序列化后再反序列化应该保持数据完整性', () {
      final original = Command(
        id: 'test-1',
        name: '测试命令',
        command: 'echo "hello"',
        createdAt: DateTime.parse('2026-01-12T10:00:00.000Z'),
        modifiedAt: DateTime.parse('2026-01-12T11:00:00.000Z'),
        pinned: true,
        pinnedAt: DateTime.parse('2026-01-12T12:00:00.000Z'),
      );

      final json = original.toJson();
      final restored = Command.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.command, original.command);
      expect(restored.createdAt, original.createdAt);
      expect(restored.modifiedAt, original.modifiedAt);
      expect(restored.pinned, original.pinned);
      expect(restored.pinnedAt, original.pinnedAt);
    });

    test('copyWith应该正确修改指定字段', () {
      final original = Command(
        id: 'test-1',
        name: '测试命令',
        command: 'echo "hello"',
        createdAt: DateTime.parse('2026-01-12T10:00:00.000Z'),
        modifiedAt: DateTime.parse('2026-01-12T10:00:00.000Z'),
      );

      final updated = original.copyWith(
        name: '更新后的命令',
        pinned: true,
        pinnedAt: DateTime.parse('2026-01-12T11:00:00.000Z'),
      );

      expect(updated.id, original.id); // 未修改
      expect(updated.name, '更新后的命令'); // 已修改
      expect(updated.command, original.command); // 未修改
      expect(updated.pinned, true); // 已修改
      expect(updated.pinnedAt, DateTime.parse('2026-01-12T11:00:00.000Z')); // 已修改
    });
  });
}
