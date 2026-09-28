import Defaults
import SwiftUI

// An NSPanel subclass that implements floating panel traits.
// https://stackoverflow.com/questions/46023769/how-to-show-a-window-without-stealing-focus-on-macos
class FloatingPanel<Content: View>: NSPanel, NSWindowDelegate {
  var isPresented: Bool = false
  var statusBarButton: NSStatusBarButton?
  let onClose: () -> Void

  private var hostedContentView: NSView?
  private var contentContainerView: NSView?
  private var presentedInterfaceStyle: InterfaceStyle?
  private var bottomStripAnimationGeneration = 0
  private var isBottomStripDismissing = false
  private var isFinishingClose = false
  private var bottomStripPreviewPanel: NSPanel?
  private var bottomStripPreviewAnimationGeneration = 0
  private var bottomStripActionAfterClose: (() -> Void)?
  private var applicationBeforeBottomStripPresentation: NSRunningApplication?

  override var isMovable: Bool {
    get { Defaults[.interfaceStyle] == .floatingWindow && Defaults[.popupPosition] != .statusItem }
    set {}
  }

  init(
    contentRect: NSRect,
    identifier: String = "",
    statusBarButton: NSStatusBarButton? = nil,
    onClose: @escaping () -> Void,
    view: () -> Content
  ) {
    self.onClose = onClose

    super.init(
        contentRect: contentRect,
        styleMask: [.nonactivatingPanel, .resizable, .closable, .fullSizeContentView],
        backing: .buffered,
        defer: false
    )

    self.statusBarButton = statusBarButton
    self.identifier = NSUserInterfaceItemIdentifier(identifier)

    Defaults[.windowSize] = contentRect.size
    delegate = self

    animationBehavior = .none
    isFloatingPanel = true
    // Chrome autofill uses window layer 999; screenSaver (1000) sits just above it
    // while still covering status items / Spotlight. See #1403.
    level = .screenSaver
    collectionBehavior = [.auxiliary, .stationary, .moveToActiveSpace, .fullScreenAuxiliary]
    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    isMovableByWindowBackground = true
    hidesOnDeactivate = false
    backgroundColor = .clear
    titlebarSeparatorStyle = .none

    // Hide all traffic light buttons
    standardWindowButton(.closeButton)?.isHidden = true
    standardWindowButton(.miniaturizeButton)?.isHidden = true
    standardWindowButton(.zoomButton)?.isHidden = true

    let hostedContentView = NSHostingView(
      rootView: view()
        // The safe area is ignored because the title bar still interferes with the geometry
        .ignoresSafeArea()
        .gesture(DragGesture()
          .onEnded { _ in
            self.saveWindowPosition()
        })
    )
    hostedContentView.frame = NSRect(origin: .zero, size: contentRect.size)
    hostedContentView.autoresizingMask = [.width, .height]

    let contentContainerView = NSView(frame: NSRect(origin: .zero, size: contentRect.size))
    contentContainerView.wantsLayer = true
    contentContainerView.layer?.masksToBounds = true
    contentContainerView.layer?.cornerRadius = Popup.cornerRadius + Popup.horizontalPadding
    contentContainerView.addSubview(hostedContentView)

    self.hostedContentView = hostedContentView
    self.contentContainerView = contentContainerView
    contentView = contentContainerView
  }

  func toggle(height: CGFloat, at popupPosition: PopupPosition = Defaults[.popupPosition]) {
    if isPresented {
      close()
    } else {
      open(height: height, at: popupPosition)
    }
  }

  func open(height: CGFloat, at popupPosition: PopupPosition = Defaults[.popupPosition]) {
    if Defaults[.interfaceStyle] == .bottomStrip {
      applicationBeforeBottomStripPresentation = nil
      if let frontmostApplication = NSWorkspace.shared.frontmostApplication,
         frontmostApplication.processIdentifier != ProcessInfo.processInfo.processIdentifier {
        applicationBeforeBottomStripPresentation = frontmostApplication
      }
      openBottomStrip()
      return
    }

    // The floating presentation remains user-resizable. The bottom strip
    // removes this mask while it is open, so restore it when switching back.
    styleMask.insert(.resizable)
    bottomStripAnimationGeneration += 1
    isBottomStripDismissing = false
    presentedInterfaceStyle = .floatingWindow
    hasShadow = true

    let size = Defaults[.windowSize]
    let miniumHeight: CGFloat = AppState.shared.popup.minimumHeight
    let finalWidth = min(frame.width, size.width)
    let finalHeight = max(min(height, size.height), miniumHeight)
    setContentSize(NSSize(width: finalWidth, height: finalHeight))
    setFrameOrigin(popupPosition.origin(size: frame.size, statusBarButton: statusBarButton))
    resetHostedContentFrame()
    contentContainerView?.layer?.cornerRadius = Popup.cornerRadius + Popup.horizontalPadding
    orderFrontRegardless()
    makeKey()
    isPresented = true

    if popupPosition == .statusItem {
      DispatchQueue.main.async {
        self.statusBarButton?.isHighlighted = true
      }
    }
  }

  private func openBottomStrip() {
    let screen = NSScreen.activeForBottomStrip ?? NSScreen.main
    guard let visibleFrame = screen?.visibleFrame else { return }

    // The strip has a deliberately tuned geometry; resizing it creates empty
    // space without improving the card layout.
    styleMask.remove(.resizable)
    AppState.shared.preview.cancelAutoOpen()
    AppState.shared.preview.state = .closed

    let frame = BottomStripGeometry.frame(
      in: visibleFrame,
      preferredSize: Defaults[.bottomStripSize]
    )

    bottomStripAnimationGeneration += 1
    let animationGeneration = bottomStripAnimationGeneration
    isBottomStripDismissing = false
    presentedInterfaceStyle = .bottomStrip
    hasShadow = false

    setFrame(frame, display: false)
    contentContainerView?.layoutSubtreeIfNeeded()
    contentContainerView?.layer?.cornerRadius = BottomStripGeometry.cornerRadius
    setHostedContentOffset(y: -frame.height)
    orderFrontRegardless()
    makeKey()
    isPresented = true

    contentContainerView?.displayIfNeeded()
    DispatchQueue.main.async { [weak self] in
      self?.revealBottomStrip(animationGeneration: animationGeneration)
    }
  }

  /// Builds the hidden strip's view hierarchy once during app startup so its
  /// first shortcut invocation does not also pay SwiftUI and material setup.
  func warmUpBottomStrip() {
    guard !isPresented, Defaults[.interfaceStyle] == .bottomStrip else { return }
    guard let visibleFrame = NSScreen.activeForBottomStrip?.visibleFrame else { return }

    styleMask.remove(.resizable)
    let frame = BottomStripGeometry.frame(
      in: visibleFrame,
      preferredSize: Defaults[.bottomStripSize]
    )
    setFrame(frame, display: false)
    resetHostedContentFrame()
    contentContainerView?.layoutSubtreeIfNeeded()
    contentContainerView?.displayIfNeeded()
  }

  func toggleBottomStripPreview() {
    guard presentedInterfaceStyle == .bottomStrip, isPresented else { return }

    if AppState.shared.preview.state.isOpen {
      hideBottomStripPreview(animated: true)
    } else {
      guard AppState.shared.navigator.leadHistoryItem != nil else { return }
      showBottomStripPreview()
    }
  }

  private func showBottomStripPreview() {
    let previewPanel = bottomStripPreviewPanel ?? makeBottomStripPreviewPanel()
    bottomStripPreviewPanel = previewPanel
    bottomStripPreviewAnimationGeneration += 1
    let animationGeneration = bottomStripPreviewAnimationGeneration

    let finalFrame = bottomStripPreviewFrame()
    var initialFrame = finalFrame
    initialFrame.origin.y -= 8

    AppState.shared.preview.state = .opening
    previewPanel.alphaValue = 0
    previewPanel.setFrame(initialFrame, display: false)
    addChildWindow(previewPanel, ordered: .above)
    previewPanel.orderFrontRegardless()

    guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
      previewPanel.setFrame(finalFrame, display: true)
      previewPanel.alphaValue = 1
      AppState.shared.preview.state = .open
      return
    }

    NSAnimationContext.runAnimationGroup({ context in
      context.duration = 0.2
      context.timingFunction = CAMediaTimingFunction(name: .easeOut)
      previewPanel.animator().setFrame(finalFrame, display: true)
      previewPanel.animator().alphaValue = 1
    }, completionHandler: { [weak self] in
      guard let self, animationGeneration == self.bottomStripPreviewAnimationGeneration else { return }
      AppState.shared.preview.state = .open
    })
  }

  private func hideBottomStripPreview(animated: Bool) {
    guard let previewPanel = bottomStripPreviewPanel, previewPanel.isVisible else {
      AppState.shared.preview.state = .closed
      return
    }

    bottomStripPreviewAnimationGeneration += 1
    let animationGeneration = bottomStripPreviewAnimationGeneration
    AppState.shared.preview.state = .closing

    let finish = { [weak self, weak previewPanel] in
      guard let self, animationGeneration == self.bottomStripPreviewAnimationGeneration else { return }
      if let previewPanel {
        self.removeChildWindow(previewPanel)
        previewPanel.orderOut(nil)
        previewPanel.alphaValue = 1
      }
      AppState.shared.preview.state = .closed
    }

    guard animated, !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
      finish()
      return
    }

    var targetFrame = previewPanel.frame
    targetFrame.origin.y -= 8
    NSAnimationContext.runAnimationGroup({ context in
      context.duration = 0.16
      context.timingFunction = CAMediaTimingFunction(name: .easeIn)
      previewPanel.animator().setFrame(targetFrame, display: true)
      previewPanel.animator().alphaValue = 0
    }, completionHandler: finish)
  }

  private func makeBottomStripPreviewPanel() -> NSPanel {
    let previewPanel = NSPanel(
      contentRect: bottomStripPreviewFrame(),
      styleMask: [.nonactivatingPanel, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )
    previewPanel.animationBehavior = .none
    previewPanel.backgroundColor = .clear
    previewPanel.becomesKeyOnlyIfNeeded = true
    previewPanel.collectionBehavior = collectionBehavior
    previewPanel.hasShadow = true
    previewPanel.hidesOnDeactivate = false
    previewPanel.isFloatingPanel = true
    previewPanel.isMovable = false
    previewPanel.isReleasedWhenClosed = false
    previewPanel.level = level

    let hostingView = NSHostingView(rootView: BottomStripPreviewSurface())
    hostingView.wantsLayer = true
    hostingView.layer?.cornerRadius = BottomStripGeometry.previewCornerRadius
    hostingView.layer?.masksToBounds = true
    previewPanel.contentView = hostingView
    return previewPanel
  }

  private func bottomStripPreviewFrame() -> NSRect {
    let visibleFrame = screen?.visibleFrame ?? NSScreen.activeForBottomStrip?.visibleFrame ?? frame
    let width = min(BottomStripGeometry.previewWidth, max(1, frame.width - 32))
    let availableHeight = max(1, visibleFrame.maxY - frame.maxY - BottomStripGeometry.previewGap - 12)
    let height = min(BottomStripGeometry.previewHeight, availableHeight)

    return NSRect(
      x: min(max(frame.midX - width / 2, frame.minX + 16), frame.maxX - width - 16),
      y: frame.maxY + BottomStripGeometry.previewGap,
      width: width,
      height: height
    )
  }

  private func revealBottomStrip(animationGeneration: Int) {
    guard
      animationGeneration == bottomStripAnimationGeneration,
      presentedInterfaceStyle == .bottomStrip,
      isPresented,
      !isBottomStripDismissing
    else { return }

    let targetFrame = contentContainerView?.bounds ?? .zero
    guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
      hostedContentView?.frame = targetFrame
      hasShadow = true
      return
    }

    NSAnimationContext.runAnimationGroup({ context in
      context.duration = 0.25
      context.timingFunction = CAMediaTimingFunction(name: .easeOut)
      hostedContentView?.animator().frame = targetFrame
    }, completionHandler: { [weak self] in
      guard let self, animationGeneration == self.bottomStripAnimationGeneration else { return }
      self.hasShadow = true
    })
  }

  private func dismissBottomStrip() {
    guard !isBottomStripDismissing else { return }

    bottomStripAnimationGeneration += 1
    let animationGeneration = bottomStripAnimationGeneration
    isBottomStripDismissing = true
    hasShadow = false

    var targetFrame = contentContainerView?.bounds ?? .zero
    targetFrame.origin.y = -targetFrame.height

    guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
      hostedContentView?.frame = targetFrame
      finishClose(animationGeneration: animationGeneration)
      return
    }

    NSAnimationContext.runAnimationGroup({ context in
      context.duration = 0.2
      context.timingFunction = CAMediaTimingFunction(name: .easeIn)
      hostedContentView?.animator().frame = targetFrame
    }, completionHandler: { [weak self] in
      self?.finishClose(animationGeneration: animationGeneration)
    })
  }

  private func setHostedContentOffset(y: CGFloat) {
    guard let bounds = contentContainerView?.bounds else { return }
    hostedContentView?.frame = NSRect(
      x: bounds.minX,
      y: y,
      width: bounds.width,
      height: bounds.height
    )
  }

  private func resetHostedContentFrame() {
    guard let bounds = contentContainerView?.bounds else { return }
    hostedContentView?.frame = bounds
  }

  func verticallyResize(to newHeight: CGFloat) {
    var newSize = frame.size
    newSize.height = newHeight
    var newOrigin = frame.origin
    newOrigin.y += (frame.height - newSize.height)

    NSAnimationContext.runAnimationGroup { (context) in
      context.duration = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : 0.2
      animator().setFrame(NSRect(origin: newOrigin, size: newSize), display: true)
    }
  }

  func determinePreviewPlacement() {
    let preview = AppState.shared.preview
    guard !preview.state.isOpen else { return }
    let newSize = preview.computeSizeWithPreview(frame.size, state: .open)
    preview.placement = preview.computePlacement(window: self, for: newSize)
  }

  func saveWindowPosition() {
    if let screenFrame = screen?.visibleFrame {
      // Only store the size of the window without the preview
      let width = AppState.shared.preview.contentWidth

      let anchorX = frame.minX + width / 2 - screenFrame.minX
      let anchorY = frame.maxY - screenFrame.minY
      Defaults[.windowPosition] = NSPoint(x: anchorX / screenFrame.width, y: anchorY / screenFrame.height)
    }
  }

  func saveWindowFrame(frame: NSRect) {
    if Defaults[.interfaceStyle] == .bottomStrip {
      Defaults[.bottomStripSize] = frame.size
    } else {
      Defaults[.windowSize] = frame.size
      saveWindowPosition()
    }
  }

  func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
    if Defaults[.interfaceStyle] == .bottomStrip {
      let visibleFrame = sender.screen?.visibleFrame ?? NSScreen.activeForBottomStrip?.visibleFrame
      var finalSize = frameSize
      finalSize.width = visibleFrame.map(BottomStripGeometry.width(in:)) ?? finalSize.width
      finalSize.height = min(max(finalSize.height, BottomStripGeometry.minimumHeight), BottomStripGeometry.maximumHeight)
      Defaults[.bottomStripSize] = finalSize
      return finalSize
    }

    let preview = AppState.shared.preview

    if inLiveResize && preview.resizingMode == .none {
      let screenPoint = NSEvent.mouseLocation
      let windowPoint = convertPoint(fromScreen: screenPoint)
      let location: SlideoutPlacement = windowPoint.x <= frame.width / 2 ? .left : .right
      if (location == preview.placement) && preview.state == .open {
        preview.startResize(mode: .slideout)
      } else {
        preview.startResize(mode: .content)
      }
    }

    var finalFrameSize = frameSize
    var minContent = preview.minimumContentWidth
    var minPreview = 0.0

    if inLiveResize && preview.resizingMode != .none {
      if preview.resizingMode == .content && preview.state == .open {
        minPreview = preview.slideoutWidth
      }
      if preview.resizingMode == .slideout {
        minPreview = preview.minimumSlideoutWidth
        minContent = preview.contentWidth
      }
    }
    finalFrameSize.width = max(finalFrameSize.width, minContent + minPreview)

    if !AppState.shared.preview.state.isAnimating {
      var size = frame.size
      // Only store the size of the window without the preview
      size.width = AppState.shared.preview.contentWidth
      saveWindowFrame(frame: NSRect(origin: frame.origin, size: size))
    }

    let minimumHeight = AppState.shared.popup.minimumHeight
    finalFrameSize.height = max(finalFrameSize.height, minimumHeight)

    return finalFrameSize
  }

  func windowWillMove(_ notification: Notification) {
    determinePreviewPlacement()
  }

  func windowDidMove(_ notification: Notification) {
    determinePreviewPlacement()
  }

  func windowWillStartLiveResize(_ notification: Notification) {
    AppState.shared.preview.cancelAutoOpen()
  }

  func windowDidEndLiveResize(_ notification: Notification) {
    AppState.shared.preview.startAutoOpen()
    AppState.shared.preview.endResize()
  }

  func windowDidBecomeKey(_ notification: Notification) {
    AppState.shared.preview.enableAutoOpen()

    if AppState.shared.navigator.leadHistoryItem != nil {
      AppState.shared.preview.startAutoOpen()
    }
  }

  func windowDidResignKey(_ notification: Notification) {
    AppState.shared.preview.disableAutoOpen()
  }

  // Close automatically when out of focus, e.g. outside click.
  override func resignKey() {
    super.resignKey()
    // Don't hide if confirmation is shown.
    if NSApp.alertWindow == nil {
      close()
    }
  }

  override func close() {
    guard isPresented, !isFinishingClose else { return }

    if presentedInterfaceStyle == .bottomStrip {
      dismissBottomStrip()
    } else {
      finishClose()
    }
  }

  func close(after action: @escaping () -> Void) {
    guard isPresented else {
      action()
      return
    }

    guard presentedInterfaceStyle == .bottomStrip else {
      close()
      action()
      return
    }

    // Ignore repeated activation while the strip is already dismissing so a
    // rapid second Return or double-click cannot paste the item twice.
    guard bottomStripActionAfterClose == nil else { return }
    bottomStripActionAfterClose = action
    close()
  }

  private func finishClose(animationGeneration: Int? = nil) {
    if let animationGeneration, animationGeneration != bottomStripAnimationGeneration {
      return
    }

    guard isPresented, !isFinishingClose else { return }

    isFinishingClose = true
    hideBottomStripPreview(animated: false)
    isPresented = false
    presentedInterfaceStyle = nil
    isBottomStripDismissing = false
    bottomStripAnimationGeneration += 1
    let bottomStripAction = bottomStripActionAfterClose
    bottomStripActionAfterClose = nil
    let applicationToReactivate = applicationBeforeBottomStripPresentation
    applicationBeforeBottomStripPresentation = nil

    super.close()
    AppState.shared.preview.state = .closed
    statusBarButton?.isHighlighted = false
    resetHostedContentFrame()
    hasShadow = true
    isFinishingClose = false
    onClose()

    if let bottomStripAction {
      applicationToReactivate?.activate()
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: bottomStripAction)
    }

  }

  // Allow text inputs inside the panel can receive focus
  override var canBecomeKey: Bool {
    return true
  }
}
