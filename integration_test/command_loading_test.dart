import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paste_manager/services/command_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('命令加载调试测试', () {
    testWidgets('验证 CommandService 能从主目录加载命令', (WidgetTester tester) async {
      final service = CommandService();

      print('开始测试 CommandService...');
      print('HOME 目录: ${Platform.environment['HOME']}');

      final testFile = File('${Platform.environment['HOME']}/.paste_manager.json');
      print('配置文件路径: ${testFile.path}');
      print('文件是否存在: ${await testFile.exists()}');

      if (await testFile.exists()) {
        final content = await testFile.readAsString();
        print('文件大小: ${content.length} 字节');
        print('文件前200字符: ${content.substring(0, content.length > 200 ? 200 : content.length)}');
      }

      try {
        await service.initialize();
        print('✅ 初始化成功');
        print('命令数量: ${service.currentCommands.length}');

        for (var i = 0; i < service.currentCommands.length; i++) {
          final cmd = service.currentCommands[i];
          print('  [$i] ${cmd.name} (置顶: ${cmd.pinned})');
        }

        expect(service.currentCommands.length, greaterThan(0),
            reason: '应该加载至少一个命令');
      } catch (e, stack) {
        print('❌ 测试失败: $e');
        print('堆栈: $stack');
        rethrow;
      } finally {
        service.dispose();
      }
    });
  });
}
