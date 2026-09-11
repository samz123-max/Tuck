import AppKit
import Defaults
import Foundation
import SwiftUI

final class DockWindowCoordinator: @unchecked Sendable {
  typealias PolicySetter = (NSApplication.ActivationPolicy) -> Bool

  private var closeObservers: [ObjectIdentifier: NSObjectProtocol] = [:]
  private let setActivationPolicy: PolicySetter
  private let activateApplication: () -> Void

  init(
    setActivationPolicy: @escaping PolicySetter = { NSApp.setActivationPolicy($0) },
    activateApplication: @escaping () -> Void = { NSApp.activate(ignoringOtherApps: true) }
  ) {
    self.setActivationPolicy = setActivationPolicy
    self.activateApplication = activateApplication
  }

  @MainActor
  func prepareForWindowPresentation() {
    _ = setActivationPolicy(.regular)
    activateApplication()
  }

  @MainActor
  func track(_ window: NSWindow) {
    let identifier = ObjectIdentifier(window)
    guard closeObservers[identifier] == nil else { return }

    closeObservers[identifier] = NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification,
      object: window,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor [weak self] in
        self?.windowDidClose(identifier)
      }
    }
  }

  @MainActor
  private func windowDidClose(_ identifier: ObjectIdentifier) {
    if let observer = closeObservers.removeValue(forKey: identifier) {
      NotificationCenter.default.removeObserver(observer)
    }
    if closeObservers.isEmpty {
      _ = setActivationPolicy(.accessory)
    }
  }
}

@Observable
class AppState: Sendable {
  static let shared = AppState(history: History.shared, footer: Footer())

  let multiSelectionEnabled = false

  var appDelegate: AppDelegate?
  var popup: Popup
  var history: History
  var footer: Footer
  var navigator: NavigationManager
  var preview: SlideoutController

  var searchVisible: Bool {
    if !Defaults[.showSearch] { return false }
    switch Defaults[.searchVisibility] {
    case .always: return true
    case .duringSearch: return !history.searchQuery.isEmpty
    }
  }

  var menuIconText: String {
    var title = history.unpinnedItems.first?.text.shortened(to: 100)
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    title.unicodeScalars.removeAll(where: CharacterSet.newlines.contains)
    return title.shortened(to: 20)
  }

  private let about = About()
  private let dockWindows = DockWindowCoordinator()
  private var settingsWindowController: NSWindowController?

  init(history: History, footer: Footer) {
    self.history = history
    self.footer = footer
    popup = Popup()
    navigator = NavigationManager(history: history, footer: footer)
    preview = SlideoutController(
      onContentResize: { contentWidth in
        Defaults[.windowSize].width = contentWidth
      },
      onSlideoutResize: { previewWidth in
        Defaults[.previewWidth] = previewWidth
      })
    preview.contentWidth = Defaults[.windowSize].width
    preview.slideoutWidth = Defaults[.previewWidth]
  }

  @MainActor
  func select(flags modifierFlags: NSEvent.ModifierFlags) {
    if !navigator.selection.isEmpty {
      if navigator.isMultiSelectInProgress {
        navigator.isManualMultiSelect = false
        history.startPasteStack(selection: &navigator.selection, flags: modifierFlags)
      } else {
        history.select(navigator.selection.first, flags: modifierFlags)
      }
    } else if let item = footer.selectedItem {
      // TODO: Use item.suppressConfirmation, but it's not updated!
      if item.confirmation != nil, Defaults[.suppressClearAlert] == false {
        item.showConfirmation = true
      } else {
        item.action()
      }
    } else {
      Clipboard.shared.copyInTuck(history.searchQuery)
      history.searchQuery = ""
    }
  }

  @MainActor
  func togglePin() {
    withTransaction(Transaction()) {
      navigator.selection.forEach { _, item in
        history.togglePin(item)
      }
    }
  }

  @MainActor
  func removePasteStack() {
    history.interruptPasteStack()
    navigator.highlightFirst()
  }

  @MainActor
  func deleteSelection() {
    guard let leadItem = navigator.leadHistoryItem else { return }
    let nextUnselectedItem = history.visibleItems.nearest(to: leadItem) { !$0.isSelected }

    withTransaction(Transaction()) {
      navigator.selection.forEach { _, item in
        history.delete(item)
      }
      navigator.select(item: nextUnselectedItem)
    }
  }

  @MainActor
  func openAbout() {
    dockWindows.prepareForWindowPresentation()
    if let window = about.open() {
      dockWindows.track(window)
    }
  }

  @MainActor
  func openPreferences() {
    dockWindows.prepareForWindowPresentation()
    if settingsWindowController == nil {
      let rootView = GeneralSettingsPane()
        .environment(self)
        .modelContainer(Storage.shared.container)
      let hostingController = NSHostingController(rootView: rootView)
      let window = NSWindow(contentViewController: hostingController)
      window.title = "Tuck Settings"
      window.identifier = NSUserInterfaceItemIdentifier("TuckSettings")
      window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
      window.titlebarAppearsTransparent = true
      window.titlebarSeparatorStyle = .none
      window.toolbarStyle = .unified
      window.setContentSize(NSSize(width: 860, height: 620))
      window.minSize = NSSize(width: 760, height: 540)
      window.setFrameAutosaveName("TuckSettingsWindow")
      window.center()
      window.isReleasedWhenClosed = false
      settingsWindowController = NSWindowController(window: window)
    }
    if let window = settingsWindowController?.window {
      dockWindows.track(window)
    }
    settingsWindowController?.showWindow(nil)
    settingsWindowController?.window?.orderFrontRegardless()
  }

  func quit() {
    NSApp.terminate(self)
  }
}
