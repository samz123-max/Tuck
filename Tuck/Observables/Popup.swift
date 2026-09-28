import AppKit.NSRunningApplication
import Defaults
import KeyboardShortcuts
import Observation

enum InterfaceStyle: String, CaseIterable, Identifiable, Defaults.Serializable {
  case floatingWindow
  case bottomStrip

  var id: Self { self }

  var title: String {
    switch self {
    case .floatingWindow: "Floating Window"
    case .bottomStrip: "Bottom Strip"
    }
  }

  var settingsDescription: String {
    switch self {
    case .floatingWindow:
      "A compact clipboard window that opens where you choose."
    case .bottomStrip:
      "A wide, visual clipboard surface along the bottom of the active display."
    }
  }
}

enum ListStyle: String, CaseIterable, Identifiable, Defaults.Serializable {
  case compact
  case comfortable
  case detailed

  var id: Self { self }

  static var settingsLabel: String {
    localized("ListStyle", fallback: "List style:")
  }

  var title: String {
    let fallback = switch self {
    case .compact: "Compact"
    case .comfortable: "Comfortable"
    case .detailed: "Detailed"
    }
    return Self.localized("ListStyle\(rawValue.capitalized)", fallback: fallback)
  }

  var settingsDescription: String {
    let fallback = switch self {
    case .compact: "More clipboard history at a glance."
    case .comfortable: "Balanced spacing that is easy to scan. Tuck’s default."
    case .detailed: "Adds the source app and relative copy time to each row."
    }
    return Self.localized("ListStyle\(rawValue.capitalized)Description", fallback: fallback)
  }

  var rowHeight: CGFloat {
    switch self {
    case .compact: 28
    case .comfortable: 32
    case .detailed: 42
    }
  }

  var iconSize: CGFloat {
    self == .compact ? 15 : 16
  }

  var rowInset: CGFloat {
    self == .compact ? 0 : 8
  }

  var contentSpacing: CGFloat {
    self == .compact ? 5 : 7
  }

  var titleTrailingPadding: CGFloat {
    self == .compact ? 5 : 8
  }

  var trailingPadding: CGFloat {
    self == .compact ? 10 : 8
  }

  var showsDetails: Bool {
    self == .detailed
  }

  private static func localized(_ key: String, fallback: String) -> String {
    let value = NSLocalizedString(key, tableName: "AppearanceSettings", comment: "")
    return value == key ? fallback : value
  }
}

enum PopupState {
  // Default; shortcut will toggle the popup
  case toggle
  // In this mode, every additional press of the main key
  // will cycle to the next item in the paste history list.
  // Releasing the modifier keys will accept selection and close the popup
  case cycle
  // Transition state when the shortcut is first pressed and
  // we don't know whether we are in "toggle" or "cycle" mode.
  case opening
}

@Observable
class Popup {
  static let verticalSeparatorPadding = 8.0
  static let horizontalSeparatorPadding = 12.0
  static let verticalPadding: CGFloat = 7
  static let horizontalPadding: CGFloat = 8
  static let minimumPreviewHeight: CGFloat = 150

  // Radius used for items inset by the padding. Ensures they visually have the same curvature
  // as the menu.
  static let cornerRadius: CGFloat = 10

  // Default height for controls that share the list-item component. History
  // rows use the user's selected ListStyle height.
  static let itemHeight: CGFloat = 32

  var needsResize = false
  var height: CGFloat = 0
  var headerHeight: CGFloat = 0
  var extraTopHeight: CGFloat = 0
  var extraBottomHeight: CGFloat = 0
  var footerHeight: CGFloat = 0

  var minimumHeight: CGFloat {
    // Reserve space for 3 items
    return suitableHeight(for: 3 * Defaults[.listStyle].rowHeight)
  }

  private var eventsMonitor: Any?

  private var state: PopupState = .toggle

  init() {
    KeyboardShortcuts.onKeyDown(for: .popup, action: handleFirstKeyDown)
    initEventsMonitor()
  }

  deinit {
    deinitEventsMonitor()
  }

  func initEventsMonitor() {
    guard eventsMonitor == nil else { return }

    self.eventsMonitor = NSEvent.addLocalMonitorForEvents(
      matching: [.flagsChanged, .keyDown],
      handler: handleEvent
    )
  }

  func deinitEventsMonitor() {
    guard let eventsMonitor else { return }

    NSEvent.removeMonitor(eventsMonitor)
  }

  func open(height: CGFloat, at popupPosition: PopupPosition = Defaults[.popupPosition]) {
    AppState.shared.appDelegate?.panel.open(height: height, at: popupPosition)
  }

  func reset() {
    AppState.shared.history.category = .all
    state = .toggle
    KeyboardShortcuts.enable(.popup)
  }

  func close() {
    AppState.shared.appDelegate?.panel.close()  // close() calls reset
  }

  func close(after action: @escaping () -> Void) {
    guard let panel = AppState.shared.appDelegate?.panel else {
      action()
      return
    }
    panel.close(after: action)  // close() calls reset
  }

  func isClosed() -> Bool {
    AppState.shared.appDelegate?.panel.isPresented != true
  }

  func preferredHeight(for newHeight: CGFloat) -> CGFloat {
    var height = newHeight

    var minHeight = self.minimumHeight
    // If the preview is non-empty make sure the window accomodates for it to be visible.
    if AppState.shared.preview.state.isOpen && AppState.shared.navigator.leadSelection != nil {
      minHeight = max(minHeight, Self.minimumPreviewHeight)
    }
    minHeight = max(headerHeight + Self.verticalPadding, minHeight)

    height = max(height, minHeight)
    height = min(height, Defaults[.windowSize].height)
    return height
  }

  private func suitableHeight(for historyListHeight: CGFloat) -> CGFloat {
    return historyListHeight + headerHeight + extraTopHeight + extraBottomHeight + footerHeight
  }

  func resize(height: CGFloat) {
    self.height = suitableHeight(for: height)
    AppState.shared.appDelegate?.panel.verticallyResize(to: preferredHeight(for: self.height))
    needsResize = false
  }

  private func handleFirstKeyDown() {
    if isClosed() {
      open(height: height)
      state = .opening
      KeyboardShortcuts.disable(.popup)  // Handle events via eventsMonitor. Re-enable on popup close
      return
    }

    // Tuck was not opened via shortcut. We assume toggle mode and close it
    close()
  }

  private func handleEvent(_ event: NSEvent) -> NSEvent? {
    switch event.type {
    case .keyDown:
      return handleKeyDown(event)
    case .flagsChanged:
      return handleFlagsChanged(event)
    default:
      return event
    }
  }

  private func handleKeyDown(_ event: NSEvent) -> NSEvent? {
    if isHotKeyCode(Int(event.keyCode)) {
      if let item = History.shared.pressedShortcutItem {
        AppState.shared.navigator.select(item: item)
        let modifierFlags = NSEvent.ModifierFlags.currentModifierFlags
        Task { @MainActor in
          AppState.shared.history.select(item, flags: modifierFlags)
        }
        return nil
      }

      if state == .opening {
        state = .cycle
        // Next 'if' will highlight next item and then return nil
      }

      if state == .cycle {
        AppState.shared.navigator.highlightNext(allowCycle: true)
        return nil
      }

      if state == .toggle && isHotKeyModifiers(event.modifierFlags) {
        close()
        return nil
      }
    }

    return event
  }

  private func handleFlagsChanged(_ event: NSEvent) -> NSEvent? {
    // If we are in cycle mode, releasing modifiers triggers a selection
    if state == .cycle && allModifiersReleased(event) {
      let modifierFlags = NSEvent.ModifierFlags.currentModifierFlags
      DispatchQueue.main.async {
        AppState.shared.select(flags: modifierFlags)
      }
      return nil
    }

    // Otherwise if in opening mode, enter toggle mode
    if state == .opening && allModifiersReleased(event) {
      state = .toggle
      return event
    }

    return event
  }

  private func isHotKeyCode(_ keyCode: Int) -> Bool {
    guard let shortcut = KeyboardShortcuts.Name.popup.shortcut else {
      return false
    }

    return shortcut.key?.rawValue == keyCode
  }

  private func isHotKeyModifiers(_ modifiers: NSEvent.ModifierFlags) -> Bool {
    guard let shortcut = KeyboardShortcuts.Name.popup.shortcut else {
      return false
    }

    return modifiers.intersection(.deviceIndependentFlagsMask) ==
      shortcut.modifiers.intersection(.deviceIndependentFlagsMask)
  }

  private func allModifiersReleased(_ event: NSEvent) -> Bool {
    return event.modifierFlags.isDisjoint(with: .deviceIndependentFlagsMask)
  }
}
