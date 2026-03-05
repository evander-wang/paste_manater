import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 存储路径辅助工具类
/// 统一处理应用支持目录下的文件路径获取
class StoragePathHelper {
  /// 获取应用支持目录下的文件路径
  /// 自动创建不存在的目录
  ///
  /// 参数:
  /// - [appName] 应用名称，用于创建子目录
  /// - [filename] 文件名
  ///
  /// 返回: 完整的文件路径
  static Future<String> getFilePath(String appName, String filename) async {
    final appSupportDir = await getApplicationSupportDirectory();
    final appDir = Directory('${appSupportDir.path}/$appName');

    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }

    return '${appDir.path}/$filename';
  }
}
