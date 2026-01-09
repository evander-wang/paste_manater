import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()

    // 设置内容视图控制器（必须在设置窗口大小之前）
    self.contentViewController = flutterViewController

    // 设置窗口初始大小
    let initialWindowSize = NSSize(width: 618, height: 900)
    self.setFrame(NSRect(origin: self.frame.origin, size: initialWindowSize), display: true)

    // 设置窗口最小尺寸
    self.minSize = NSSize(width: 500, height: 700)

    // 设置窗口最大尺寸（可选，防止窗口过大）
    self.maxSize = NSSize(width: 1200, height: 1400)

    // 注册生成的插件（如果有）
    RegisterGeneratedPlugins(registry: flutterViewController)

    // 注册自定义插件
    ClipboardMonitorPlugin.register(with: flutterViewController.registrar(forPlugin: "ClipboardMonitorPlugin"))
    HotkeyPlugin.register(with: flutterViewController.registrar(forPlugin: "HotkeyPlugin"))

    print("✅ 自定义插件已注册在 MainFlutterWindow")
    print("📐 窗口大小: \(initialWindowSize.width) x \(initialWindowSize.height)")

    super.awakeFromNib()
  }
}
