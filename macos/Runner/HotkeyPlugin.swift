import Cocoa
import FlutterMacOS
import Carbon

public class HotkeyPlugin: NSObject, FlutterPlugin {
  private var methodChannel: FlutterMethodChannel?
  private var hotkeyRef: EventHotKeyRef?
  private var hotkeyCallback: (() -> Void)?
  private var mainWindow: NSWindow?

  public static func register(with registrar: FlutterPluginRegistrar) -> FlutterPluginRegistrar {
    let plugin = HotkeyPlugin()
    let channel = FlutterMethodChannel(
      name: "paste_manager/hotkey",
      binaryMessenger: registrar.messenger
    )
    plugin.methodChannel = channel
    plugin.setup(registrar)

    // 保存主窗口引用
    if let window = NSApplication.shared.windows.first {
      plugin.mainWindow = window
    }

    return registrar
  }

  private func setup(_ registrar: FlutterPluginRegistrar) {
    let channel = methodChannel!

    // 获取主窗口引用
    if let window = NSApplication.shared.windows.first {
      self.mainWindow = window
      print("✅ HotkeyPlugin 已获取主窗口引用")
    } else {
      print("⚠️ HotkeyPlugin 无法获取主窗口引用")
    }

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
      case "showWindow":
        self.showWindow(result: result)
      case "hideWindow":
        self.hideWindow(result: result)
      case "toggleWindow":
        self.toggleWindow(result: result)
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

    print("📝 尝试注册热键: keyCode=\(keyCodeString), modifiers=\(modifiersArray)")

    // 注册热键
    let hotkeySuccess = self.registerGlobalHotkey(
      keyCode: keyCode,
      modifiers: modifiers
    ) { [weak self] in
      self?.hotkeyPressed()
    }

    if hotkeySuccess {
      print("✅ 热键注册成功")
      result(true)
    } else {
      print("❌ 热键注册失败")
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
    print("🔔 热键被触发：Cmd+Shift+V")

    // 通过MethodChannel通知Flutter
    methodChannel?.invokeMethod("hotkeyPressed", arguments: nil)

    // 同时切换窗口显示/隐藏
    toggleWindow()
  }

  private func showWindow(result: FlutterResult) {
    DispatchQueue.main.async { [weak self] in
      if let window = self?.mainWindow {
        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        result(true)
      } else {
        result(false)
      }
    }
  }

  private func hideWindow(result: FlutterResult) {
    DispatchQueue.main.async { [weak self] in
      if let window = self?.mainWindow {
        window.orderOut(nil)
        result(true)
      } else {
        result(false)
      }
    }
  }

  private func toggleWindow(result: FlutterResult) {
    DispatchQueue.main.async { [weak self] in
      if let window = self?.mainWindow {
      if window.isVisible {
        window.orderOut(nil)
        result(false) // 现在是隐藏的
      } else {
        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        result(true) // 现在是显示的
      }
      } else {
        result(false)
      }
    }
  }

  private func toggleWindow() {
    DispatchQueue.main.async { [weak self] in
      // 每次都重新获取窗口引用，确保能找到
      guard let window = NSApplication.shared.windows.first ?? self?.mainWindow else {
        print("⚠️ 无法获取窗口引用")
        return
      }

      // 更新窗口引用
      self?.mainWindow = window

      if window.isVisible {
        print("🔽 隐藏窗口")
        window.orderOut(nil)
      } else {
        print("🔼 显示窗口")
        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
      }
    }
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
