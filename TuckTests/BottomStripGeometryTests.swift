import AppKit
import XCTest
@testable import Tuck

final class BottomStripGeometryTests: XCTestCase {
  func testAnchorsToBottomWithRestrainedSideInsets() {
    let visibleFrame = NSRect(x: 100, y: 48, width: 1440, height: 900)

    let frame = BottomStripGeometry.frame(
      in: visibleFrame,
      preferredSize: NSSize(width: 1200, height: 336)
    )

    XCTAssertEqual(frame, NSRect(x: 112, y: 48, width: 1416, height: 336))
  }

  func testPreferredWidthDoesNotChangeScreenRelativeWidth() {
    let visibleFrame = NSRect(x: 0, y: 0, width: 1000, height: 800)

    let frame = BottomStripGeometry.frame(
      in: visibleFrame,
      preferredSize: NSSize(width: 1600, height: 300)
    )

    XCTAssertEqual(frame.width, 976)
    XCTAssertEqual(frame.minX, 12)
  }

  func testPreservesInsetsOnNarrowOffsetDisplay() {
    let visibleFrame = NSRect(x: -800, y: 0, width: 600, height: 500)

    let frame = BottomStripGeometry.frame(
      in: visibleFrame,
      preferredSize: NSSize(width: 1280, height: 300)
    )

    XCTAssertEqual(frame.width, 576)
    XCTAssertEqual(frame.minX, -788)
    XCTAssertEqual(frame.maxX, -212)
  }

  func testClampsHeightToSupportedRange() {
    let visibleFrame = NSRect(x: 0, y: 0, width: 1440, height: 900)

    let shortFrame = BottomStripGeometry.frame(
      in: visibleFrame,
      preferredSize: NSSize(width: 1000, height: 100)
    )
    let tallFrame = BottomStripGeometry.frame(
      in: visibleFrame,
      preferredSize: NSSize(width: 1000, height: 700)
    )

    XCTAssertEqual(shortFrame.height, BottomStripGeometry.minimumHeight)
    XCTAssertEqual(tallFrame.height, BottomStripGeometry.maximumHeight)
  }
}
