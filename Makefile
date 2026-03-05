.PHONY: help dev build release clean test analyze

help:	## 显示帮助信息
	@echo "可用命令:"
	@echo "  make dev      - 编译开发包 (Debug)"
	@echo "  make build    - 编译线上包 (Release)"
	@echo "  make release  - 编译线上包 (Release, 别名)"
	@echo "  make clean    - 清理构建产物"
	@echo "  make test     - 运行测试"
	@echo "  make analyze  - 运行静态分析"
	@echo "  make run      - 运行开发版本"

dev:	## 编译开发包
	@echo "🔨 正在构建开发包..."
	flutter build macos --debug --no-tree-shake-icons
	@if [ $$? -eq 0 ]; then \
		echo "✅ 开发包构建成功！"; \
		echo "📦 应用位置: build/macos/Build/Products/Debug/paste_manager.app"; \
	else \
		echo "❌ 构建失败"; \
		exit 1; \
	fi

build:	## 编译线上包
	@echo "🔨 正在构建线上包..."
	flutter build macos --release --no-tree-shake-icons
	@if [ $$? -eq 0 ]; then \
		echo "✅ 线上包构建成功！"; \
		echo "📦 应用位置: build/macos/Build/Products/Release/paste_manager.app"; \
	else \
		echo "❌ 构建失败"; \
		exit 1; \
	fi

release: build	## 线上包别名

clean:	## 清理构建产物
	@echo "🧹 清理构建产物..."
	flutter clean
	rm -rf build/
	@echo "✅ 清理完成"

test:	## 运行测试
	@echo "🧪 运行测试..."
	flutter test

analyze:	## 运行静态分析
	@echo "🔍 运行静态分析..."
	flutter analyze

run:	## 运行开发版本
	@echo "🚀 启动开发版本..."
	flutter run -d macos
