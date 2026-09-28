import AppKit.NSEvent
import Defaults
import Foundation

enum BottomStripGeometry {
  static let horizontalInset: CGFloat = 12
  static let minimumHeight: CGFloat = 336
  static let maximumHeight: CGFloat = 460
  static let cornerRadius: CGFloat = 20
  static let previewWidth: CGFloat = 560
  static let previewHeight: CGFloat = 380
  static let previewGap: CGFloat = 8
  static let previewCornerRadius: CGFloat = 18

  static func width(in visibleFrame: NSRect) -> CGFloat {
    max(1, visibleFrame.width - horizontalInset * 2)
  }

  static func frame(in visibleFrame: NSRect, preferredSize: NSSize) -> NSRect {
    let height = min(max(preferredSize.height, minimumHeight), min(maximumHeight, visibleFrame.height))

    return NSRect(
      x: visibleFrame.minX + horizontalInset,
      y: visibleFrame.minY,
      width: width(in: visibleFrame),
      height: height
    )
  }
}

extension NSScreen {
  static var activeForBottomStrip: NSScreen? {
    let mouseLocation = NSEvent.mouseLocation
    return screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
      ?? main
      ?? screens.first
  }
}

enum PopupPosition: String, CaseIterable, Identifiable, CustomStringConvertible, Defaults.Serializable {
  case cursor
  case statusItem
  case window
  case center
  case lastPosition

  var id: Self { self }

  var description: String {
    switch self {
    case .cursor:
      return NSLocalizedString("PopupAtCursor", tableName: "AppearanceSettings", comment: "")
    case .statusItem:
      return NSLocalizedString("PopupAtMenuBarIcon", tableName: "AppearanceSettings", comment: "")
    case .window:
      return NSLocalizedString("PopupAtWindowCenter", tableName: "AppearanceSettings", comment: "")
    case .center:
      return NSLocalizedString("PopupAtScreenCenter", tableName: "AppearanceSettings", comment: "")
    case .lastPosition:
      return NSLocalizedString("PopupAtLastPosition", tableName: "AppearanceSettings", comment: "")
    }
  }

  func origin(size: NSSize, statusBarButton: NSStatusBarButton?) -> NSPoint {
    switch self {
    case .center:
      if let frame = NSScreen.forPopup?.visibleFrame {
        return NSRect.centered(ofSize: size, in: frame).origin
      }
    case .window:
      if let frame = NSWorkspace.shared.frontmostApplication?.windowFrame {
        return NSRect.centered(ofSize: size, in: frame).origin
      }
    case .statusItem:
      if let statusBarButton {
        let rectInWindow = statusBarButton.convert(statusBarButton.bounds, to: nil)
        if let screenRect = statusBarButton.window?.convertToScreen(rectInWindow) {
          let topLeftPoint = NSPoint(x: screenRect.minX, y: screenRect.minY - size.height)
          let screen = statusBarButton.window?.screen ?? NSScreen.main
          return constrained(topLeftPoint, ofSize: size, to: screen)
        }
      }
    case .lastPosition:
      if let frame = NSScreen.forPopup?.visibleFrame {
        let relativePos = Defaults[.windowPosition]
        let anchorX = frame.minX + frame.width * relativePos.x
        let anchorY = frame.minY + frame.height * relativePos.y
        // Anchor is top middle of frame
        return NSPoint(x: anchorX - size.width / 2, y: anchorY - size.height)
      }
    default:
      break
    }

    let mouseLocation = NSEvent.mouseLocation
    let point = NSPoint(x: mouseLocation.x, y: mouseLocation.y - size.height)
    let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
    return constrained(point, ofSize: size, to: screen)
  }

  // Ensure that window doesn't spill over to an adjacent screen.
  private func constrained(_ origin: NSPoint, ofSize size: NSSize, to screen: NSScreen?) -> NSPoint {
    guard let frame = screen?.visibleFrame else {
      return origin
    }

    return NSPoint(
      x: min(max(origin.x, frame.minX), frame.maxX - size.width),
      y: min(max(origin.y, frame.minY), frame.maxY - size.height)
    )
  }
}
