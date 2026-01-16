import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// 自定义分类存储服务
/// 负责从本地文件系统加载和保存自定义分类数据
class CategoryStorage {
  static const String _categoriesFileName = 'custom_categories.json';
  static const String _backupFileName = 'custom_categories.json.bak';
  static const int _currentVersion = 1;

  /// 获取自定义分类文件路径
  Future<File> _getCategoriesFile() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final pasteManagerDir = Directory('${appSupportDir.path}/paste_manager');

    if (!await pasteManagerDir.exists()) {
      await pasteManagerDir.create(recursive: true);
    }

    final file = File('${pasteManagerDir.path}/$_categoriesFileName');
    return file;
  }

  /// 获取备份文件路径
  Future<File> _getBackupFile() async {
    final categoriesFile = await _getCategoriesFile();
    final backupPath = categoriesFile.path + '.bak';
    return File(backupPath);
  }

  /// 创建备份
  Future<void> backupCategories() async {
    try {
      final sourceFile = await _getCategoriesFile();
      if (await sourceFile.exists()) {
        final backupFile = await _getBackupFile();
        await sourceFile.copy(backupFile.path);
        debugPrint('CategoryStorage: Backup created at ${backupFile.path}');
      }
    } catch (e) {
      debugPrint('CategoryStorage: Backup failed - $e');
      rethrow;
    }
  }

  /// 保存自定义分类列表到文件
  /// 使用原子写入:先写入临时文件,然后重命名
  Future<void> saveCategories(List<Map<String, dynamic>> categoriesJson) async {
    try {
      // 1. 创建备份
      await backupCategories();

      // 2. 准备数据
      final data = {
        'version': _currentVersion,
        'categories': categoriesJson,
      };

      // 3. 原子写入
      final file = await _getCategoriesFile();
      final tempFile = File('${file.path}.tmp');

      await tempFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
      );

      // 4. 重命名(原子操作)
      await tempFile.rename(file.path);

      debugPrint('CategoryStorage: Saved ${categoriesJson.length} categories');
    } catch (e) {
      debugPrint('CategoryStorage: Save failed - $e');
      rethrow;
    }
  }

  /// 从文件加载自定义分类列表
  Future<List<Map<String, dynamic>>> loadCategories() async {
    try {
      final file = await _getCategoriesFile();

      if (!await file.exists()) {
        debugPrint('CategoryStorage: No categories file exists, returning empty list');
        return [];
      }

      final jsonString = await file.readAsString();
      final data = json.decode(jsonString) as Map<String, dynamic>;

      // 检查版本
      final version = data['version'] as int? ?? 1;
      if (version < _currentVersion) {
        debugPrint('CategoryStorage: Old version $version, current is $_currentVersion');
        // TODO: 执行迁移逻辑
      }

      final categories = data['categories'] as List<dynamic>? ?? [];
      debugPrint('CategoryStorage: Loaded ${categories.length} categories');

      return categories.cast<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('CategoryStorage: Load failed - $e');
      // 如果加载失败,尝试从备份恢复
      final backupFile = await _getBackupFile();
      if (await backupFile.exists()) {
        debugPrint('CategoryStorage: Attempting to restore from backup');
        final backupString = await backupFile.readAsString();
        final data = json.decode(backupString) as Map<String, dynamic>;
        final categories = data['categories'] as List<dynamic>? ?? [];
        return categories.cast<Map<String, dynamic>>().toList();
      }
      rethrow;
    }
  }

  /// 从分类列表中移除指定分类
  Future<void> removeCategory(List<Map<String, dynamic>> categoriesJson, String categoryId) async {
    // 创建备份
    await backupCategories();

    // 移除分类
    categoriesJson.removeWhere((category) => category['id'] == categoryId);

    // 保存更新后的列表
    await saveCategories(categoriesJson);

    debugPrint('CategoryStorage: Removed category $categoryId');
  }
}
