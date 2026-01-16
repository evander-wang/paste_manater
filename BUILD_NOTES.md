# 构建说明

## macOS 应用构建

由于应用实现了自定义分类功能，允许用户创建包含动态图标的分类，因此构建时必须禁用 Flutter 的图标 tree-shaking 优化。

### 快速构建

使用提供的构建脚本：

```bash
./build_macos.sh
```

### 手动构建

如果需要手动构建，请使用以下命令：

```bash
flutter build macos --release --no-tree-shake-icons
```

### 为什么需要 `--no-tree-shake-icons`？

Flutter 的 tree-shaking 优化会删除未使用的图标以减小应用体积。但是，自定义分类功能允许用户在运行时动态选择图标，这意味着所有 Material Icons 都可能被使用，无法在编译时确定。因此必须禁用此优化。

### 构建产物

构建成功后，应用位于：
```
build/macos/Build/Products/Release/paste_manager.app
```

### 其他平台

目前仅支持 macOS 平台。如果需要添加其他平台支持，请参考相应的构建配置。
