import 'package:flutter/material.dart';
import '../models/category_base.dart';
import 'add_category_dialog.dart';
import 'delete_category_dialog.dart';
import '../services/category_manager.dart';

/// 分类过滤器组件
///
/// 现代化的分段控制器设计，支持自定义分类、添加新分类、水平滚动
class CategoryFilterWidget extends StatefulWidget {
  /// 当前选中的分类ID
  final String? selectedCategoryId;

  /// 分类切换回调
  final ValueChanged<String?> onCategoryToggle;

  /// 每个分类的计数
  final Map<String, int> categoryCounts;

  /// 总记录数
  final int totalCount;

  /// 分类管理器
  final CategoryManager categoryManager;

  const CategoryFilterWidget({
    super.key,
    required this.selectedCategoryId,
    required this.onCategoryToggle,
    required this.categoryCounts,
    required this.totalCount,
    required this.categoryManager,
  });

  @override
  State<CategoryFilterWidget> createState() => _CategoryFilterWidgetState();
}

class _CategoryFilterWidgetState extends State<CategoryFilterWidget> {
  // T077: 添加滚动控制器
  final ScrollController _scrollController = ScrollController();

  // 用于存储分类按钮的GlobalKey,用于自动滚动
  // 关键修复：不要在每次更新时清空并重新创建 keys，保持 keys 的稳定性
  final Map<String?, GlobalKey> _categoryKeys = {};

  // T074F: 宽度约束常量
  static const double MIN_BUTTON_WIDTH = 60.0;
  static const double MAX_BUTTON_WIDTH = 200.0;
  static const double BUTTON_SPACING = 3.0;
  static const int ANIMATION_DURATION = 300; // ms

  // T074M: 宽度计算缓存
  double? _cachedAvailableWidth;
  int? _cachedCategoryCount;
  double? _cachedButtonWidth;

  @override
  void initState() {
    super.initState();
    // 初始化时为"全部"和所有分类创建key
    _updateCategoryKeys();
  }

  @override
  void didUpdateWidget(CategoryFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当选中的分类变化时,自动滚动到可视区域
    if (widget.selectedCategoryId != oldWidget.selectedCategoryId) {
      _scrollToSelectedCategory();
    }
    // T074D/T074E: 当分类列表变化时,更新keys并重新计算宽度
    final currentCategories = widget.categoryManager.getAllCategories();
    final oldCategories = oldWidget.categoryManager.getAllCategories();
    if (currentCategories.length != oldCategories.length) {
      _updateCategoryKeys();
      // T074M: 清除缓存,因为分类数量变化了
      _cachedButtonWidth = null;
      _cachedAvailableWidth = null;
      _cachedCategoryCount = null;
      // T074I: 延迟滚动,等待UI重建和动画完成
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedCategory();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 更新分类按键映射
  void _updateCategoryKeys() {
    // 不再清空所有 keys，而是添加缺失的 keys
    // 这样可以保持现有 keys 的稳定性，避免 widget 重建
    if (!_categoryKeys.containsKey(null)) {
      _categoryKeys[null] = GlobalKey();
    }
    for (var category in widget.categoryManager.getAllCategories()) {
      if (!_categoryKeys.containsKey(category.id)) {
        _categoryKeys[category.id] = GlobalKey();
      }
    }

    // 清理已删除分类的 keys
    final currentIds = <String?>[null, ...widget.categoryManager.getAllCategories().map((c) => c.id)];
    _categoryKeys.removeWhere((key, value) => !currentIds.contains(key));
  }

  /// T076: 滚动到选中的分类
  void _scrollToSelectedCategory() {
    final key = _categoryKeys[widget.selectedCategoryId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// T074A: 计算分类按钮宽度
  double _calculateCategoryButtonWidth(double availableWidth, int categoryCount) {
    // 检查缓存
    if (_cachedAvailableWidth == availableWidth &&
        _cachedCategoryCount == categoryCount &&
        _cachedButtonWidth != null) {
      return _cachedButtonWidth!;
    }

    // T074O: 验证不同屏幕尺寸的可用宽度
    // 确保可用宽度在合理范围内(处理极端屏幕尺寸)
    final validatedWidth = availableWidth.clamp(200.0, 4000.0);

    // 计算总宽度需求
    final totalCategories = categoryCount + 1; // +1 for "全部"按钮
    final totalSpacing = totalCategories * BUTTON_SPACING;
    final idealButtonWidth = (validatedWidth - totalSpacing) / totalCategories;

    double buttonWidth;
    if (idealButtonWidth >= MAX_BUTTON_WIDTH) {
      // 理想宽度超过最大值,使用最大宽度并启用横向滚动
      buttonWidth = MAX_BUTTON_WIDTH;
    } else if (idealButtonWidth <= MIN_BUTTON_WIDTH) {
      // 理想宽度小于最小值,使用最小宽度
      buttonWidth = MIN_BUTTON_WIDTH;
    } else {
      // 在范围内,使用理想宽度
      buttonWidth = idealButtonWidth;
    }

    // 更新缓存
    _cachedAvailableWidth = availableWidth;
    _cachedCategoryCount = categoryCount;
    _cachedButtonWidth = buttonWidth;

    return buttonWidth;
  }

  /// T074B: 判断是否应该启用横向滚动
  bool _shouldEnableHorizontalScroll(double availableWidth, int categoryCount) {
    final totalCategories = categoryCount + 1; // +1 for "全部"按钮
    final totalSpacing = totalCategories * BUTTON_SPACING;
    final idealButtonWidth = (availableWidth - totalSpacing) / totalCategories;

    // 如果理想宽度大于最大宽度,需要横向滚动
    return idealButtonWidth > MAX_BUTTON_WIDTH;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allCategories = widget.categoryManager.getAllCategories();
    final categoryCount = allCategories.length;

    // T074L: 使用LayoutBuilder获取可用宽度
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 32 - 6; // 减去margin和padding
        final buttonWidth = _calculateCategoryButtonWidth(availableWidth, categoryCount);
        final shouldScroll = _shouldEnableHorizontalScroll(availableWidth, categoryCount);

        // T074N: 添加日志记录
        print(
          'CategoryFilterWidget: 宽度适配 - '
          '可用宽度: ${availableWidth.toStringAsFixed(1)}px, '
          '分类数: $categoryCount, '
          '按钮宽度: ${buttonWidth.toStringAsFixed(1)}px, '
          '启用滚动: $shouldScroll'
        );

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              // 分类按钮区域（支持水平滚动）
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController, // T077: 使用滚动控制器
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Row(
                    children: [
                      // "全部"按钮
                      _buildFilterButton(
                        context,
                        key: _categoryKeys[null],
                        buttonWidth: buttonWidth,
                        shouldScroll: shouldScroll,
                        categoryId: null,
                        label: '全部',
                        count: widget.totalCount,
                        icon: Icons.apps_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      // 所有分类按钮(预置 + 自定义),带间距
                      ...allCategories.map((categoryBase) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: BUTTON_SPACING),
                            _buildFilterButton(
                              context,
                              key: _categoryKeys[categoryBase.id],
                              buttonWidth: buttonWidth,
                              shouldScroll: shouldScroll,
                              categoryBase: categoryBase,
                              categoryId: categoryBase.id,
                              label: categoryBase.displayName,
                              count: widget.categoryCounts[categoryBase.id] ?? 0,
                              icon: categoryBase.icon,
                              color: categoryBase.color,
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
              // "+"按钮（添加自定义分类）
              const SizedBox(width: 3),
              _buildAddCategoryButton(context),
            ],
          ),
        );
      },
    );
  }

  /// 构建过滤器按钮
  Widget _buildFilterButton(
    BuildContext context, {
    Key? key,
    required double buttonWidth, // T074G: 应用宽度约束
    required bool shouldScroll, // 滚动状态
    CategoryBase? categoryBase,
    required String? categoryId,
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = widget.selectedCategoryId == categoryId;
    final theme = Theme.of(context);

    // T074H: 使用AnimatedContainer应用300ms宽度调整动画
    // 注意: key 用于滚动定位，不能放在 AnimatedContainer 上，否则 key 变化会打断动画
    return Material(
      key: key, // 将 key 放在 Material 层，用于滚动定位
      color: isSelected
          ? color
          : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: ANIMATION_DURATION),
        curve: Curves.easeInOut,
        width: buttonWidth, // 动态宽度
        child: GestureDetector(
          onLongPress: categoryBase != null && !categoryBase.isPreset
              ? () => _showDeleteCategoryDialog(context, categoryBase, count)
              : null,
          child: InkWell(
            onTap: () => widget.onCategoryToggle(categoryId),
            borderRadius: BorderRadius.circular(9),
            // T074K: 添加Tooltip组件
            child: Tooltip(
              message: label, // 鼠标悬停显示完整名称
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isSelected ? Colors.white : color.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 2),
                    // T074J: 实现文本溢出省略号
                    SizedBox(
                      width: double.infinity, // 占满可用宽度
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        overflow: TextOverflow.ellipsis, // 省略号截断
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(height: 1),
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.8)
                              : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建"+"按钮
  Widget _buildAddCategoryButton(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: _showAddCategoryDialog,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Icon(
            Icons.add,
            size: 20,
            color: theme.colorScheme.primary.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  /// 显示添加分类对话框
  Future<void> _showAddCategoryDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddCategoryDialog(
        onSubmitted: (name) async {
          await widget.categoryManager.addCategory(name);
          // 刷新UI
          setState(() {});
        },
      ),
    );

    // 对话框关闭后刷新UI
    if (result == true && mounted) {
      setState(() {});
    }
  }

  /// 显示删除分类对话框
  Future<void> _showDeleteCategoryDialog(
    BuildContext context,
    CategoryBase categoryBase,
    int itemCount,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => DeleteCategoryDialog(
        category: categoryBase,
        itemCount: itemCount,
      ),
    );

    // 如果确认删除
    if (result == true && mounted) {
      try {
        await widget.categoryManager.deleteCategory(categoryBase.id);

        // 如果删除的是当前选中的分类,切换到"全部"
        if (widget.selectedCategoryId == categoryBase.id && mounted) {
          widget.onCategoryToggle(null);
        }

        // 刷新UI
        if (mounted) {
          setState(() {});
        }
      } on Exception catch (e) {
        // 显示错误提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }
}
