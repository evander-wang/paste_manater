import Cocoa
import FlutterMacOS
import Carbon

// MARK: - Clipboard Monitor Plugin

class ClipboardMonitorPlugin: NSObject, FlutterPlugin {
  private var methodChannel: FlutterMethodChannel?
  private var pasteboard: NSPasteboard?
  private var timer: Timer?
  private var lastChangeCount: Int = 0

  // 静态实例持有，防止被释放
  private static var instance: ClipboardMonitorPlugin?

  static func register(with registrar: FlutterPluginRegistrar) {
    let plugin = ClipboardMonitorPlugin()
    instance = plugin  // 持有实例

    let channel = FlutterMethodChannel(
      name: "paste_manager/clipboard",
      binaryMessenger: registrar.messenger
    )
    plugin.methodChannel = channel
    plugin.setup()
  }

  private func setup() {
    let channel = methodChannel!

    channel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE",
                             message: "ClipboardMonitor not available",
                             details: nil))
        return
      }

      print("📥 收到方法调用: \(call.method)")

      switch call.method {
      case "startMonitoring":
        self.startMonitoring(result: result)
      case "stopMonitoring":
        self.stopMonitoring(result: result)
      case "getClipboardData":
        self.getClipboardData(result: result)
      default:
        print("⚠️ 未知方法: \(call.method)")
        result(FlutterMethodNotImplemented)
      }
    }
    print("✅ ClipboardMonitor 方法处理器已设置")
  }

  private func startMonitoring(result: FlutterResult) {
    pasteboard = NSPasteboard.general
    lastChangeCount = pasteboard?.changeCount ?? 0

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
    }
  }

  private func getClipboardData(result: FlutterResult) {
    guard let pasteboard = pasteboard else {
      result(FlutterError(code: "UNAVAILABLE",
                         message: "Pasteboard not available",
                         details: nil))
      return
    }

    let changeCount = pasteboard.changeCount
    let content = pasteboard.string(forType: .string) ?? ""

    let data: [String: Any?] = [
      "content": content,
      "changeCount": changeCount,
      "sourceApp": nil,
    ]

    result(data)
  }

  func detach() {
    timer?.invalidate()
    timer = nil
    methodChannel = nil
    pasteboard = nil
  }
}

// MARK: - Hotkey Plugin

class HotkeyPlugin: NSObject, FlutterPlugin {
  private var methodChannel: FlutterMethodChannel?
  private var hotkeyRef: EventHotKeyRef?
  private var eventHandlerRef: EventHandlerRef?
  private var mainWindow: NSWindow?
  private var isWindowVisible = true  // 手动跟踪窗口可见性

  // 静态实例持有，防止被释放
  private static var instance: HotkeyPlugin?

  static func register(with registrar: FlutterPluginRegistrar) {
    let plugin = HotkeyPlugin()
    instance = plugin  // 持有实例

    let channel = FlutterMethodChannel(
      name: "paste_manager/hotkey",
      binaryMessenger: registrar.messenger
    )
    plugin.methodChannel = channel
    plugin.setup()

    // 保存主窗口引用
    if let window = NSApplication.shared.windows.first {
      plugin.mainWindow = window
    }
  }

  private func setup() {
    let channel = methodChannel!

    // 获取主窗口引用
    if let window = NSApplication.shared.windows.first {
      self.mainWindow = window
      print("✅ HotkeyPlugin 已获取主窗口引用")
    } else {
      print("⚠️ HotkeyPlugin 无法获取主窗口引用")
    }

    // 注册窗口焦点变化通知
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(windowDidResignKey),
      name: NSWindow.didResignKeyNotification,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationDidBecomeActive),
      name: NSApplication.didBecomeActiveNotification,
      object: nil
    )
    print("✅ 已注册焦点变化通知监听")

    channel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE",
                             message: "HotkeyPlugin not available",
                             details: nil))
        return
      }

      print("📥 HotkeyPlugin 收到方法调用: \(call.method)")

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
      case "resignFocus":
        self.resignFocus(result: result)
      default:
        print("⚠️ HotkeyPlugin 未知方法: \(call.method)")
        result(FlutterMethodNotImplemented)
      }
    }
    print("✅ HotkeyPlugin 方法处理器已设置")
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
      return self?.hotkeyPressed() ?? false
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
    // 移除事件处理器
    if let handlerRef = eventHandlerRef {
      RemoveEventHandler(handlerRef)
      eventHandlerRef = nil
    }

    // 注销热键
    if let hotkeyRef = hotkeyRef {
      UnregisterEventHotKey(hotkeyRef)
      self.hotkeyRef = nil
    }

    result(nil)
  }

  private func registerGlobalHotkey(
    keyCode: UInt32,
    modifiers: UInt32,
    callback: @escaping () -> Bool
  ) -> Bool {
    // 移除旧的热键
    if let hotkeyRef = hotkeyRef {
      UnregisterEventHotKey(hotkeyRef)
      self.hotkeyRef = nil
    }

    // 移除旧的事件处理器
    if let handlerRef = eventHandlerRef {
      RemoveEventHandler(handlerRef)
      eventHandlerRef = nil
    }

    // 定义热键类型和ID
    let hotkeySignature = FourCharCode(0x68746b79) // 'htky'
    let hotkeyID = EventHotKeyID(signature: hotkeySignature, id: 1)

    // 将修饰键转换为 Carbon 格式
    var carbonModifiers: UInt32 = 0
    if modifiers & UInt32(cmdKey) != 0 {
      carbonModifiers |= UInt32(cmdKey)
    }
    if modifiers & UInt32(shiftKey) != 0 {
      carbonModifiers |= UInt32(shiftKey)
    }
    if modifiers & UInt32(optionKey) != 0 {
      carbonModifiers |= UInt32(optionKey)
    }
    if modifiers & UInt32(controlKey) != 0 {
      carbonModifiers |= UInt32(controlKey)
    }

    // 注册热键
    var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
    let status = RegisterEventHotKey(
      keyCode,
      carbonModifiers,
      hotkeyID,
      GetApplicationEventTarget(),
      0,
      &hotkeyRef
    )

    if status == noErr {
      print("✅ Carbon 热键注册成功 (keyCode=\(keyCode), modifiers=\(carbonModifiers))")

      // 保存 self 引用（使用 passRetained 确保不会提前释放）
      let selfPtr = Unmanaged.passRetained(self).toOpaque()

      // 安装事件处理器并保存引用
      var handlerRef: EventHandlerRef?
      let installStatus = InstallEventHandler(
        GetApplicationEventTarget(),
        { (nextHandler, theEvent, userData) -> OSStatus in
          guard let userData = userData else {
            return noErr
          }

          let unmanagedSelf = Unmanaged<HotkeyPlugin>.fromOpaque(userData)
          let `self` = unmanagedSelf.takeUnretainedValue()

          print("🔔 热键事件被触发 (Carbon)")

          // 在主线程调用热键处理
          DispatchQueue.main.async {
            _ = self.hotkeyPressed()
          }

          return noErr
        },
        1,
        &eventType,
        selfPtr,
        &handlerRef
      )

      if installStatus == noErr && handlerRef != nil {
        self.eventHandlerRef = handlerRef
        print("✅ 事件处理器已安装并保存引用")
        return true
      } else {
        print("❌ 事件处理器安装失败: \(installStatus)")
        // 清理 self 引用
        Unmanaged<HotkeyPlugin>.fromOpaque(selfPtr).release()
        return false
      }
    } else {
      print("❌ Carbon 热键注册失败: \(status)")
      print("💡 提示：如果返回 -50，可能需要授予辅助功能权限")
      return false
    }
  }

  private func hotkeyPressed() -> Bool {
    print("🔔 热键被触发：Cmd+Shift+V")

    // 通过MethodChannel通知Flutter
    methodChannel?.invokeMethod("hotkeyPressed", arguments: nil)

    // 同时切换窗口显示/隐藏
    toggleWindow()

    return true
  }

  private func showWindow(result: @escaping FlutterResult) {
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

  private func hideWindow(result: @escaping FlutterResult) {
    DispatchQueue.main.async { [weak self] in
      if let window = self?.mainWindow {
        // 隐藏窗口但保持应用运行：只设置透明度和orderOut
        window.alphaValue = 0.0
        window.orderOut(nil)
        // 不改变 activation policy，避免应用退出
        result(true)
      } else {
        result(false)
      }
    }
  }

  private func resignFocus(result: @escaping FlutterResult) {
    DispatchQueue.main.async { [weak self] in
      guard self?.mainWindow != nil else {
        print("⚠️ resignFocus: 无法获取窗口引用")
        result(false)
        return
      }

      print("🔔 resignFocus: 让窗口失去焦点")
      // 让应用失去焦点,这会触发 windowDidResignKey 回调自动最小化窗口
      NSApp.hide(nil)
      result(true)
    }
  }

  private func toggleWindow(result: @escaping FlutterResult) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      guard let window = self.mainWindow else {
        print("⚠️ toggleWindow: 无法获取窗口引用")
        result(false)
        return
      }

      // 使用手动跟踪的状态而不是 isMiniaturized
      if self.isWindowVisible {
        print("🔽 通过 toggleWindow 最小化窗口到 Dock")
        // 最小化窗口到 Dock
        window.miniaturize(nil)
        self.isWindowVisible = false
        result(false) // 现在是最小化的
      } else {
        print("🔼 通过 toggleWindow 恢复窗口（从最小化）")
        // 从 Dock 恢复窗口
        window.deminiaturize(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.isWindowVisible = true
        result(true) // 现在是显示的
      }
    }
  }

  private func toggleWindow() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      // 每次都重新获取窗口引用，确保能找到
      guard let window = NSApplication.shared.windows.first ?? self.mainWindow else {
        print("⚠️ 无法获取窗口引用")
        return
      }

      // 更新窗口引用
      self.mainWindow = window

      // 使用手动跟踪的状态而不是 isMiniaturized
      if self.isWindowVisible {
        print("🔽 最小化窗口到 Dock")
        // 最小化窗口到 Dock
        window.miniaturize(nil)
        self.isWindowVisible = false
      } else {
        print("🔼 恢复窗口（从最小化）")
        // 从 Dock 恢复窗口
        window.deminiaturize(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.isWindowVisible = true
      }
    }
  }

  // 窗口失去焦点时自动隐藏
  @objc private func windowDidResignKey(_ notification: Notification) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self,
            let window = self.mainWindow ?? NSApplication.shared.windows.first else {
        return
      }

      // 只有在窗口可见时才自动隐藏
      if self.isWindowVisible {
        print("🔔 窗口失去焦点，自动最小化")
        self.isWindowVisible = false
        window.miniaturize(nil)
      }
    }
  }

  // 应用重新获得焦点时恢复窗口
  @objc private func applicationDidBecomeActive(_ notification: Notification) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self,
            let window = self.mainWindow ?? NSApplication.shared.windows.first else {
        return
      }

      // 只有在窗口被最小化时才自动恢复
      if !self.isWindowVisible && window.isMiniaturized {
        print("🔔 应用获得焦点，自动恢复窗口")
        self.isWindowVisible = true
        window.deminiaturize(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
      }
    }
  }

  func detach() {
    // 移除事件监听器
    if let handlerRef = eventHandlerRef {
      RemoveEventHandler(handlerRef)
      eventHandlerRef = nil
    }

    // 移除通知观察者
    NotificationCenter.default.removeObserver(self)

    // 注销热键
    if let hotkeyRef = hotkeyRef {
      UnregisterEventHotKey(hotkeyRef)
      self.hotkeyRef = nil
    }

    methodChannel = nil
  }

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

// MARK: - Status Bar Plugin

class StatusItemPlugin: NSObject, FlutterPlugin {
  private var methodChannel: FlutterMethodChannel?
  private var statusItem: NSStatusItem?
  private var statusItemMenu: NSMenu?

  // 静态实例持有，防止被释放
  private static var instance: StatusItemPlugin?

  static func register(with registrar: FlutterPluginRegistrar) {
    let plugin = StatusItemPlugin()
    instance = plugin  // 持有实例

    let channel = FlutterMethodChannel(
      name: "paste_manager/status_item",
      binaryMessenger: registrar.messenger
    )
    plugin.methodChannel = channel
    plugin.setup()

    print("✅ StatusItemPlugin 已注册")
  }

  private func setup() {
    let channel = methodChannel!

    // 创建状态栏图标
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    // 设置图标（使用文本图标，兼容旧版本）
    if let button = statusItem?.button {
      // 使用 "📋" 作为图标（剪贴板符号）
      button.title = "📋"
    }

    // 创建菜单
    setupMenu()

    channel.setMethodCallHandler { [weak self] (call, result) in
      guard self != nil else {
        result(FlutterError(code: "UNAVAILABLE",
                             message: "StatusItemPlugin not available",
                             details: nil))
        return
      }

      print("📥 StatusItemPlugin 收到方法调用: \(call.method)")

      // 目前没有实现的方法
      print("⚠️ StatusItemPlugin 未知方法: \(call.method)")
      result(FlutterMethodNotImplemented)
    }
    print("✅ StatusItemPlugin 方法处理器已设置")
  }

  private func setupMenu() {
    let menu = NSMenu()

    // 退出应用
    let quitItem = NSMenuItem(
      title: "退出",
      action: #selector(quitApplication),
      keyEquivalent: "q"
    )
    quitItem.target = self
    menu.addItem(quitItem)

    statusItemMenu = menu
    statusItem?.menu = menu
  }

  @objc private func quitApplication() {
    print("👋 菜单点击: 退出应用")
    NSApplication.shared.terminate(nil)
  }

  func detach() {
    // 移除状态栏图标
    if let statusItem = statusItem {
      NSStatusBar.system.removeStatusItem(statusItem)
      self.statusItem = nil
    }

    statusItemMenu = nil
    methodChannel = nil
  }
}

// MARK: - AppDelegate

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // 窗口隐藏后不退出应用，这样热键功能才能继续工作
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // 插件注册已移至 MainFlutterWindow.swift 的 awakeFromNib 方法
  // 这样可以确保在 Flutter 引擎初始化时立即注册，而不是延迟
}
