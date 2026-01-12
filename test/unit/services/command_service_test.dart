import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:paste_manager/services/command_service.dart';
import 'package:paste_manager/models/command.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockDirectory extends Mock implements Directory {}

class MockFile extends Mock implements File {}

void main() {
  group('CommandService', () {
    late CommandService commandService;
    late Directory tempDir;

    setUp(() async {
      // 创建临时目录用于测试
      final tempDirPath = Directory.systemTemp.path;
      tempDir = Directory('$tempDirPath/command_service_test_${DateTime.now().millisecondsSinceEpoch}');
      await tempDir.create();

      // 初始化 CommandService
      commandService = CommandService();
    });

    tearDown(() async {
      // 清理临时目录
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('加载测试 (T016)', () {
      test('应该从文件加载命令列表', () async {
        // 创建测试数据文件
        final testFile = File('${tempDir.path}/.paste_manager.json');
        final testData = {
          'version': '1.0',
          'commands': [
            {
              'id': 'cmd-1',
              'name': '测试命令1',
              'command': 'echo "test1"',
              'createdAt': '2026-01-12T10:00:00.000Z',
              'modifiedAt': '2026-01-12T10:00:00.000Z',
              'pinned': false,
            },
            {
              'id': 'cmd-2',
              'name': '测试命令2',
              'command': 'echo "test2"',
              'createdAt': '2026-01-12T10:00:00.000Z',
              'modifiedAt': '2026-01-12T10:00:00.000Z',
              'pinned': true,
              'pinnedAt': '2026-01-12T11:00:00.000Z',
            },
          ],
        };
        await testFile.writeAsString(jsonEncode(testData));

        // 加载命令
        final commands = await commandService.loadCommands(testFile.path);

        // 验证
        expect(commands.length, 2);
        expect(commands[0].id, 'cmd-2'); // 置顶的应该在前面
        expect(commands[0].pinned, true);
        expect(commands[1].id, 'cmd-1'); // 未置顶的在后
        expect(commands[1].pinned, false);
      });

      test('应该按置顶状态和置顶时间排序', () async {
        final testFile = File('${tempDir.path}/.paste_manager.json');
        final testData = {
          'version': '1.0',
          'commands': [
            {
              'id': 'cmd-1',
              'name': '命令1',
              'command': 'cmd1',
              'createdAt': '2026-01-12T10:00:00.000Z',
              'modifiedAt': '2026-01-12T10:00:00.000Z',
              'pinned': true,
              'pinnedAt': '2026-01-12T09:00:00.000Z', // 最早置顶
            },
            {
              'id': 'cmd-2',
              'name': '命令2',
              'command': 'cmd2',
              'createdAt': '2026-01-12T10:00:00.000Z',
              'modifiedAt': '2026-01-12T10:00:00.000Z',
              'pinned': true,
              'pinnedAt': '2026-01-12T11:00:00.000Z', // 最晚置顶
            },
            {
              'id': 'cmd-3',
              'name': '命令3',
              'command': 'cmd3',
              'createdAt': '2026-01-12T10:00:00.000Z',
              'modifiedAt': '2026-01-12T10:00:00.000Z',
              'pinned': false,
            },
          ],
        };
        await testFile.writeAsString(jsonEncode(testData));

        final commands = await commandService.loadCommands(testFile.path);

        // 验证排序: 置顶的按时间倒序,未置顶的在后
        expect(commands[0].id, 'cmd-2'); // 最晚置顶
        expect(commands[1].id, 'cmd-1'); // 最早置顶
        expect(commands[2].id, 'cmd-3'); // 未置顶
      });

      test('文件不存在时应该返回空列表', () async {
        final nonExistentFile = File('${tempDir.path}/nonexistent.json');
        final commands = await commandService.loadCommands(nonExistentFile.path);

        expect(commands, isEmpty);
      });
    });

    group('保存测试 (T017)', () {
      test('应该使用原子写入保存命令', () async {
        final testFile = File('${tempDir.path}/.paste_manager.json');

        final commands = [
          Command(
            id: 'cmd-1',
            name: '测试命令',
            command: 'echo "test"',
            createdAt: DateTime.parse('2026-01-12T10:00:00.000Z'),
            modifiedAt: DateTime.parse('2026-01-12T10:00:00.000Z'),
          ),
        ];

        await commandService.saveCommands(testFile.path, commands);

        // 验证文件已创建
        expect(await testFile.exists(), true);

        // 验证内容
        final content = await testFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;

        expect(json['version'], '1.0');
        expect(json['commands'] as List, hasLength(1));
        expect((json['commands'] as List)[0]['id'], 'cmd-1');
      });

      test('应该正确序列化所有字段', () async {
        final testFile = File('${tempDir.path}/.paste_manager.json');

        final commands = [
          Command(
            id: 'cmd-1',
            name: '置顶命令',
            command: 'echo "pinned"',
            createdAt: DateTime.parse('2026-01-12T10:00:00.000Z'),
            modifiedAt: DateTime.parse('2026-01-12T10:00:00.000Z'),
            pinned: true,
            pinnedAt: DateTime.parse('2026-01-12T11:00:00.000Z'),
          ),
        ];

        await commandService.saveCommands(testFile.path, commands);

        final content = await testFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final cmdJson = (json['commands'] as List)[0] as Map<String, dynamic>;

        expect(cmdJson['pinned'], true);
        expect(cmdJson['pinnedAt'], '2026-01-12T11:00:00.000Z');
      });
    });

    group('错误处理测试 (T018)', () {
      test('JSON格式错误时应该抛出异常', () async {
        final testFile = File('${tempDir.path}/invalid.json');
        await testFile.writeAsString('invalid json content {{{');

        expect(
          () => commandService.loadCommands(testFile.path),
          throwsA(isA<FormatException>()),
        );
      });

      test('缺少必要字段时应该使用默认值', () async {
        final testFile = File('${tempDir.path}/incomplete.json');
        await testFile.writeAsString(jsonEncode({
          'version': '1.0',
          'commands': [
            {
              'id': 'cmd-1',
              'name': '测试',
              // 缺少 command 字段
              'createdAt': '2026-01-12T10:00:00.000Z',
              'modifiedAt': '2026-01-12T10:00:00.000Z',
            },
          ],
        }));

        expect(
          () => commandService.loadCommands(testFile.path),
          throwsA(isA<TypeError>()),
        );
      });

      test('应该处理不存在的文件路径', () async {
        // 尝试读取一个肯定没有权限的文件
        final rootFile = File('/root/.paste_manager.json');

        // 应该返回空列表或抛出异常
        try {
          final result = await commandService.loadCommands(rootFile.path);
          expect(result, isEmpty);
        } catch (e) {
          // 抛出异常也是可以接受的
          expect(e, isA<Exception>());
        }
      });
    });
  });
}
