import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()

    // 设置窗口大小
    let initialWindowSize = NSSize(width: 700, height: 850)
    self.setContentSize(initialWindowSize)

    // 设置窗口最小尺寸
    self.minSize = NSSize(width: 550, height: 700)

    self.contentViewController = flutterViewController

    // 注册生成的插件（如果有）
    RegisterGeneratedPlugins(registry: flutterViewController)

    // 注册自定义插件
    ClipboardMonitorPlugin.register(with: flutterViewController.registrar(forPlugin: "ClipboardMonitorPlugin"))
    HotkeyPlugin.register(with: flutterViewController.registrar(forPlugin: "HotkeyPlugin"))

    print("✅ 自定义插件已注册在 MainFlutterWindow")

    super.awakeFromNib()
  }
}
