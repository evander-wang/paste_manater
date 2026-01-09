import Cocoa
import FlutterMacOS
import Carbon

// MARK: - Clipboard Monitor Plugin

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

// MARK: - Hotkey Plugin

public class HotkeyPlugin: NSObject, FlutterPlugin {
  private var methodChannel: FlutterMethodChannel?
  private var hotkeyRef: EventHotKeyRef?
  private var hotkeyCallback: (() -> Void)?

  public static func register(with registrar: FlutterPluginRegistrar) -> FlutterPluginRegistrar {
    let plugin = HotkeyPlugin()
    let channel = FlutterMethodChannel(
      name: "paste_manager/hotkey",
      binaryMessenger: registrar.messenger
    )
    plugin.methodChannel = channel
    plugin.setup(registrar)

    return registrar
  }

  private func setup(_ registrar: FlutterPluginRegistrar) {
    let channel = methodChannel!

    // 设置方法处理器
    channel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE",
                             message: "HotkeyPlugin not available",
                             details: nil))
        return
      }

      switch call.method {
      case "registerHotkey":
        self.registerHotkey(call: call, result: result)
      case "unregisterHotkey":
        self.unregisterHotkey(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func registerHotkey(call: FlutterMethodCall, result: FlutterResult) {
    // 解析参数
    guard let args = call.arguments as? [String: Any],
          let keyCodeString = args["keyCode"] as? String,
          let modifiersArray = args["modifiers"] as? [String] else {
      result(FlutterError(code: "INVALID_ARGUMENTS",
                         message: "Missing required arguments",
                         details: nil))
      return
    }

    // 转换按键码
    let keyCode = self.stringToKeyCode(keyCodeString)

    // 转换修饰键
    var modifiers: UInt32 = 0
    for modifierString in modifiersArray {
      modifiers |= self.stringToModifier(modifierString)
    }

    // 注册热键
    let hotkeySuccess = self.registerGlobalHotkey(
      keyCode: keyCode,
      modifiers: modifiers
    ) { [weak self] in
      self?.hotkeyPressed()
    }

    if hotkeySuccess {
      result(true)
    } else {
      result(FlutterError(code: "REGISTRATION_FAILED",
                         message: "Failed to register hotkey",
                         details: nil))
    }
  }

  private func unregisterHotkey(result: FlutterResult) {
    if let hotkeyRef = hotkeyRef {
      UnregisterEventHotKey(hotkeyRef)
      self.hotkeyRef = nil
    }
    hotkeyCallback = nil
    result(nil)
  }

  private func registerGlobalHotkey(
    keyCode: UInt32,
    modifiers: UInt32,
    callback: @escaping () -> Bool
  ) -> Bool {
    var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                  eventKind: UInt32(kEventHotKeyPressed))

    // 先注销旧的热键
    if let oldRef = hotkeyRef {
      UnregisterEventHotKey(oldRef)
    }

    let hotkeyID = EventHotKeyID(signature: OSType(0x68746B79), // 'htky'
                                  id: 1)

    var hotkeyRef: EventHotKeyRef?
    let status = RegisterEventHotKey(
      keyCode,
      modifiers,
      hotkeyID,
      GetApplicationEventTarget(),
      0,
      &hotkeyRef
    )

    if status == noErr {
      self.hotkeyRef = hotkeyRef
      self.hotkeyCallback = callback

      // 安装事件处理器
      InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
        // 调用回调
        if let callbackPtr = userData {
          let callback = unsafeBitCast(callbackPtr, to: (@convention(c) () -> Bool).self)
          _ = callback()
        }

        // 通知Flutter
        if let self = Unmanaged<HotkeyPlugin>.fromOpaque(userData!).takeUnretainedValue() as? HotkeyPlugin {
          self.methodChannel?.invokeMethod("hotkeyPressed", arguments: nil)
        }

        return noErr
      }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), nil)

      return true
    }

    return false
  }

  private func hotkeyPressed() {
    // 通过MethodChannel通知Flutter
    methodChannel?.invokeMethod("hotkeyPressed", arguments: nil)
  }

  public func detach() {
    if let hotkeyRef = hotkeyRef {
      UnregisterEventHotKey(hotkeyRef)
      self.hotkeyRef = nil
    }
    methodChannel = nil
  }

  // MARK: - Helper Methods

  private func stringToKeyCode(_ string: String) -> UInt32 {
    let keyMap: [String: UInt32] = [
      "A": 0x00, "B": 0x0B, "C": 0x08, "D": 0x02, "E": 0x0E,
      "F": 0x03, "G": 0x05, "H": 0x04, "I": 0x22, "J": 0x26,
      "K": 0x28, "L": 0x25, "M": 0x2E, "N": 0x2D, "O": 0x1F,
      "P": 0x23, "Q": 0x0C, "R": 0x0F, "S": 0x01, "T": 0x11,
      "U": 0x20, "V": 0x09, "W": 0x0D, "X": 0x07, "Y": 0x10,
      "Z": 0x06,
    ]

    return keyMap[string.uppercased()] ?? 0
  }

  private func stringToModifier(_ string: String) -> UInt32 {
    switch string {
    case "Cmd", "Command":
      return UInt32(cmdKey)
    case "Shift":
      return UInt32(shiftKey)
    case "Option", "Alt":
      return UInt32(optionKey)
    case "Control", "Ctrl":
      return UInt32(controlKey)
    case "CapsLock":
      return UInt32(alphaLock)
    default:
      return 0
    }
  }
}

