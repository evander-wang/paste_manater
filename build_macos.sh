#!/bin/bash

# macOS 应用构建脚本
# 由于自定义分类功能需要动态图标，必须禁用 tree-shake-icons

echo "🔨 正在构建 macOS 应用..."
flutter build macos --release --no-tree-shake-icons

if [ $? -eq 0 ]; then
  echo "✅ 构建成功！"
  echo "📦 应用位置: build/macos/Build/Products/Release/paste_manager.app"
else
  echo "❌ 构建失败"
  exit 1
fi
