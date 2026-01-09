import Cocoa
import FlutterMacOS
import Carbon

public class ClipboardMonitorPlugin: NSObject, FlutterPlugin {
  private var methodChannel: FlutterMethodChannel?
  private var pasteboard: NSPasteboard?
  private var timer: Timer?
  private var lastChangeCount: Int = 0

  public static func register(with registrar: FlutterPluginRegistrar) -> FlutterPluginRegistrar {
    let plugin = ClipboardMonitorPlugin()
    let channel = FlutterMethodChannel(
      name: "paste_manager/clipboard",
      binaryMessenger: registrar.messenger
    )
    plugin.methodChannel = channel
    plugin.setup(registrar)

    return registrar
  }

  private func setup(_ registrar: FlutterPluginRegistrar) {
    let channel = methodChannel!
    let controller = FlutterViewController()

    // 设置方法处理器
    channel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE",
                             message: "ClipboardMonitor not available",
                             details: nil))
        return
      }

      switch call.method {
      case "startMonitoring":
        self.startMonitoring(result: result)
      case "stopMonitoring":
        self.stopMonitoring(result: result)
      case "getClipboardData":
        self.getClipboardData(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func startMonitoring(result: FlutterResult) {
    pasteboard = NSPasteboard.general
    lastChangeCount = pasteboard?.changeCount ?? 0

    // 启动定时器，每 0.5 秒检查一次
    timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
      self?.checkClipboard()
    }

    result(nil)
  }

  private func stopMonitoring(result: FlutterResult) {
    timer?.invalidate()
    timer = nil
    result(nil)
  }

  private func checkClipboard() {
    guard let pasteboard = pasteboard else { return }

    let currentChangeCount = pasteboard.changeCount

    if currentChangeCount != lastChangeCount {
      lastChangeCount = currentChangeCount

      // 剪贴板有变化
      // 注意：实际的读取将在 getClipboardData 中完成
    }
  }

  private func getClipboardData(result: FlutterResult) {
    guard let pasteboard = pasteboard else {
      result(FlutterError(code: "UNAVAILABLE",
                         message: "Pasteboard not available",
                         details: nil))
      return
    }

    // 获取剪贴板内容
    let content = pasteboard.string(forType: .string) ?? ""
    let changeCount = pasteboard.changeCount

    // 尝试获取源应用（可能由于隐私限制而不可用）
    var sourceApp: String?
    if #available(macOS 10.14, *) {
      sourceApp = pasteboard.string(forType: .url) // 这是一个简化版本
    }

    let data: [String: Any?] = [
      "content": content,
      "changeCount": changeCount,
      "sourceApp": sourceApp,
    ]

    result(data)
  }

  public func detach() {
    timer?.invalidate()
    timer = nil
    methodChannel = nil
    pasteboard = nil
  }
}
