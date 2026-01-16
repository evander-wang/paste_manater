import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'category_storage.dart';
import 'icon_color_pool.dart';
import '../models/custom_category.dart';
import '../models/category_base.dart';
import '../models/category.dart' as model;

/// 分类相关异常基类
abstract class CategoryException implements Exception {
  final String message;
  CategoryException(this.message);

  @override
  String toString() => 'CategoryException: $message';
}

/// 分类名称为空
class CategoryNameEmptyException extends CategoryException {
  CategoryNameEmptyException() : super('分类名称不能为空');
}

/// 分类名称过长
class CategoryNameTooLongException extends CategoryException {
  CategoryNameTooLongException([int maxLength = 10])
    : super('分类名称长度不能超过$maxLength个字符');
}

/// 分类名称重复
class CategoryNameDuplicateException extends CategoryException {
  CategoryNameDuplicateException(String name)
    : super('分类"$name"已存在');
}

/// 达到分类数量上限
class CategoryLimitExceededException extends CategoryException {
  CategoryLimitExceededException([int limit = 20])
    : super('已达分类数量上限($limit个)');
}

/// 分类不存在
class CategoryNotFoundException extends CategoryException {
  CategoryNotFoundException(String id)
    : super('分类"$id"不存在');
}

/// 尝试删除预置分类
class PresetCategoryCannotBeDeletedException extends CategoryException {
  PresetCategoryCannotBeDeletedException()
    : super('系统预置分类不能被删除');
}

/// 分类不为空
class CategoryNotEmptyException extends CategoryException {
  CategoryNotEmptyException(String categoryId, int itemCount)
    : super('分类"$categoryId"下还有$itemCount个项目,无法删除');
}

/// 剪切板项目不存在
class ClipboardItemNotFoundException extends CategoryException {
  ClipboardItemNotFoundException(String id)
    : super('剪切板项目"$id"不存在');
}

/// 分类管理器
///
/// 负责管理预置分类和自定义分类的创建、删除、查询
class CategoryManager {
  final CategoryStorage _storage;
  final int maxCustomCategories;

  // 内存缓存
  List<CustomCategory>? _customCategoriesCache;

  CategoryManager({
    required CategoryStorage storage,
    this.maxCustomCategories = 20,
  }) : _storage = storage {
    // 异步加载缓存，不阻塞构造函数
    _loadCategoriesToCache().catchError((e) {
      debugPrint('CategoryManager: 初始化加载失败 - $e');
    });
  }

  /// 从存储加载分类到缓存
  Future<void> _loadCategoriesToCache() async {
    try {
      final categoriesJson = await _storage.loadCategories();
      _customCategoriesCache = categoriesJson.map((json) {
        return CustomCategory.fromJson(json);
      }).toList();
    } on Exception catch (e) {
      debugPrint('CategoryManager: 加载分类失败 - $e');
      _customCategoriesCache = [];
    }
  }

  /// 确保缓存已加载
  Future<void> _ensureCacheLoaded() async {
    if (_customCategoriesCache == null) {
      await _loadCategoriesToCache();
    }
  }

  // ========== 查询操作 ==========

  /// 获取所有分类(预置 + 自定义)
  List<CategoryBase> getAllCategories() {
    final presetCategories = model.Category.values.map((cat) {
      return PresetCategoryAdapter(cat);
    }).toList();

    final customCategories = (_customCategoriesCache ?? []).map((cat) {
      return CustomCategoryAdapter(cat);
    }).toList();

    return [...presetCategories, ...customCategories];
  }

  /// 根据ID查找分类
  CategoryBase? getCategoryById(String id) {
    // 先检查预置分类
    try {
      final presetCategory = model.Category.values.firstWhere((cat) => cat.name == id);
      return PresetCategoryAdapter(presetCategory);
    } on StateError {
      // 不是预置分类，检查自定义分类
    }

    // 检查自定义分类
    final customCategories = _customCategoriesCache ?? [];
    try {
      final category = customCategories.firstWhere((cat) => cat.id == id);
      return CustomCategoryAdapter(category);
    } on StateError {
      return null;
    }
  }

  /// 检查分类名称是否重复
  bool isNameDuplicate(String name) {
    // 检查预置分类
    for (final category in model.Category.values) {
      final adapter = PresetCategoryAdapter(category);
      if (adapter.displayName == name) {
        return true;
      }
    }

    // 检查自定义分类
    final customCategories = _customCategoriesCache ?? [];
    return customCategories.any((cat) => cat.name == name);
  }

  /// 获取分类下的项目数量
  ///
  /// 注意：此方法需要访问clipboard_history.json，暂时返回0
  /// 实际实现需要在T034中完成
  int getItemCount(String categoryId) {
    // TODO: 实现项目计数统计（T034）
    return 0;
  }

  // ========== 写入操作 ==========

  /// 创建新的自定义分类
  Future<CustomCategory> addCategory(String name) async {
    await _ensureCacheLoaded();

    // 验证名称
    validateCategoryName(name);

    // 检查重复
    if (isNameDuplicate(name)) {
      throw CategoryNameDuplicateException(name);
    }

    // 检查数量限制
    final customCategories = _customCategoriesCache!;
    if (customCategories.length >= maxCustomCategories) {
      throw CategoryLimitExceededException(maxCustomCategories);
    }

    // 创建新分类
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final category = CustomCategory(
      id: 'custom_$timestamp',
      name: name,
      icon: IconColorPool.getRandomIcon(),
      color: IconColorPool.getRandomColor(),
      createdAt: DateTime.now(),
    );

    // 添加到缓存
    _customCategoriesCache!.add(category);

    // 持久化
    final categoriesJson = _customCategoriesCache!.map((cat) => cat.toJson()).toList();
    await _storage.saveCategories(categoriesJson);

    debugPrint('CategoryManager: 创建分类成功 - ${category.name} (${category.id})');
    return category;
  }

  /// 删除自定义分类
  Future<void> deleteCategory(String categoryId) async {
    await _ensureCacheLoaded();

    // 检查分类是否存在
    final category = getCategoryById(categoryId);
    if (category == null) {
      throw CategoryNotFoundException(categoryId);
    }

    // 检查是否为预置分类
    if (category.isPreset) {
      throw PresetCategoryCannotBeDeletedException();
    }

    // 检查分类下是否还有项目
    final itemCount = getItemCount(categoryId);
    if (itemCount > 0) {
      throw CategoryNotEmptyException(categoryId, itemCount);
    }

    // 从缓存中删除
    _customCategoriesCache!.removeWhere((cat) => cat.id == categoryId);

    // 持久化 - 使用 removeCategory 方法
    final categoriesJson = _customCategoriesCache!.map((cat) => cat.toJson()).toList();
    await _storage.removeCategory(categoriesJson, categoryId);

    debugPrint('CategoryManager: 删除分类成功 - $categoryId');
  }

  /// 移动剪切板项目到指定分类
  Future<void> moveItemToCategory(
    List<Map<String, dynamic>> clipboardHistoryList,
    String itemId,
    String targetCategoryId,
  ) async {
    // 检查目标分类是否存在
    final targetCategory = getCategoryById(targetCategoryId);
    if (targetCategory == null) {
      throw CategoryNotFoundException(targetCategoryId);
    }

    // 查找并更新项目
    final itemIndex = clipboardHistoryList.indexWhere((item) => item['id'] == itemId);
    if (itemIndex == -1) {
      throw ClipboardItemNotFoundException(itemId);
    }

    final oldCategoryId = clipboardHistoryList[itemIndex]['categoryId'] as String?;

    // 更新分类
    clipboardHistoryList[itemIndex]['categoryId'] = targetCategoryId;

    debugPrint('CategoryManager: 移动项目 $itemId 从 $oldCategoryId 到 $targetCategoryId');
  }

  // ========== 验证操作 ==========

  /// 检查分类是否可以删除
  bool canDeleteCategory(String categoryId) {
    final category = getCategoryById(categoryId);
    if (category == null) {
      throw CategoryNotFoundException(categoryId);
    }

    // 预置分类不能删除
    if (category.isPreset) {
      return false;
    }

    // 分类为空才能删除
    return getItemCount(categoryId) == 0;
  }

  /// 验证分类名称
  void validateCategoryName(String name) {
    // 检查是否为空
    if (name.trim().isEmpty) {
      throw CategoryNameEmptyException();
    }

    // 检查长度
    if (name.length > 10) {
      throw CategoryNameTooLongException(10);
    }
  }

  /// 检查分类数量限制
  Future<void> checkCategoryLimit() async {
    await _ensureCacheLoaded();

    final customCategories = _customCategoriesCache!;
    if (customCategories.length >= maxCustomCategories) {
      throw CategoryLimitExceededException(maxCustomCategories);
    }
  }
}
