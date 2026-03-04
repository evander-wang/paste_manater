# Paste 剪贴板管理器

一款优雅的 macOS 剪贴板管理器,使用 Flutter 构建。

## ✨ 功能特性

- 📋 **自动剪贴板监听** - 自动捕获和保存剪贴板内容
- 🏷️ **智能分类** - 自动识别文本、链接、代码、文件和图像
- 🎨 **自定义分类** - 创建个性化分类，自定义图标和颜色
- 🖱️ **拖拽分类** - 拖拽剪贴板条目到自定义分类
- 🔍 **强大搜索** - 快速搜索剪贴板历史
- 📌 **置顶功能** - 将常用内容置顶显示
- ⌨️ **键盘快捷键** - 使用 Cmd+Shift+V 快速访问
- 🔒 **隐私保护** - 所有数据仅本地存储,忽略密码管理器

## 🚀 快速开始

### 环境要求

- macOS 10.15 (Catalina) 或更高版本
- Flutter 3.16.0 或更高版本
- Dart 3.0 或更高版本

### 安装

1. 克隆仓库:
```bash
git clone https://github.com/evander-wang/paste_manater.git
cd paste_manater
```

2. 安装依赖:
```bash
flutter pub get
```

3. 运行应用:
```bash
flutter run -d macos
```

## 🧪 运行测试

```bash
# 运行所有测试
flutter test

# 运行测试并生成覆盖率报告
flutter test --coverage

# 查看覆盖率报告
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 🏗️ 项目结构

```
lib/
├── main.dart                      # 应用入口 (128 行)
├── models/                        # 数据模型
│   ├── auto_capture_rule.dart    # 自动捕获规则
│   ├── category_base.dart        # 分类基类
│   ├── category.dart             # 预置分类枚举
│   ├── clipboard_item.dart       # 剪贴板项目
│   ├── clipboard_history.dart    # 历史记录集合
│   ├── custom_category.dart      # 自定义分类
│   ├── hotkey_config.dart        # 热键配置
│   ├── pin_status.dart           # 置顶状态接口
│   └── search_query.dart         # 搜索查询
├── services/                      # 业务服务
│   ├── categorizer.dart          # 分类器
│   ├── category_detector.dart    # 分类检测
│   ├── category_manager.dart     # 分类管理
│   ├── category_storage.dart     # 分类存储
│   ├── clipboard_monitor.dart    # 剪贴板监听
│   ├── fileWatcher_service.dart  # 文件监听
│   ├── hotkey_manager.dart       # 热键管理
│   ├── icon_color_pool.dart      # 图标颜色池
│   ├── pin_service.dart          # 置顶服务
│   ├── search_service.dart       # 搜索服务
│   └── storage_service.dart      # 存储服务
├── controllers/                   # 控制器
│   └── clipboard_history_controller.dart
├── ui/                           # UI 组件
│   ├── add_category_dialog.dart      # 添加分类对话框
│   ├── category_filter_widget.dart   # 分类过滤器 (429 行)
│   ├── clipboard_context_menu.dart   # 剪贴板上下文菜单
│   ├── clipboard_history_tab.dart    # 历史标签页 (437 行)
│   ├── clipboard_list_item_widget.dart # 剪贴板列表项
│   ├── delete_category_dialog.dart    # 删除分类对话框
│   ├── empty_state_view.dart          # 空状态视图
│   ├── move_to_category_dialog.dart   # 移动到分类对话框
│   ├── search_bar_widget.dart         # 搜索栏 (112 行)
│   └── theme/                          # 主题配置
└── widgets/                      # 其他组件
    └── monitoring_status_widget.dart
```

## 📐 架构原则

本项目遵循严格的开发宪章:

1. **松耦合架构** - 所有组件最多 2 层嵌套深度
2. **独立单元测试** - 最低 80% 代码覆盖率
3. **测试优先开发** - 遵循 TDD 红绿重构循环
4. **macOS 原生体验** - 符合 macOS HIG 规范
5. **简单性与 YAGNI** - 避免过度工程化

详见 [.specify/memory/constitution.md](.specify/memory/constitution.md)

## 🎯 开发指南

### 添加新功能

1. 使用 SpecKit 创建功能规格:
```bash
# 查看可用命令
/speckit.help
```

2. 遵循 TDD 流程:
   - 编写测试 (红色)
   - 实现功能 (绿色)
   - 重构优化 (重构)

3. 确保代码符合宪章要求:
   - 嵌套深度 ≤ 2 层
   - 测试覆盖率 ≥ 80%
   - 通过所有检查

### 代码风格

项目使用 Flutter 官方代码风格:
```bash
# 格式化代码
flutter format .

# 分析代码
flutter analyze
```

## 📝 许可证

[MIT License](LICENSE)

## 🤝 贡献

欢迎贡献! 请:

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交变更 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

**重要**: 所有 PR 必须通过宪章合规性检查,详见 PR 模板。

## 📧 联系方式

- 项目主页: [GitHub](https://github.com/evander-wang/paste_manater)
- 问题反馈: [Issues](https://github.com/evander-wang/paste_manater/issues)

---

**注意**: 本项目完全遵循项目宪章开发,确保代码质量和可维护性。
