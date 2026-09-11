import AppKit
import Defaults
import XCTest
@testable import Maccy

final class MenuIconTests: XCTestCase {
  func testVisibleOptionsAreTheTuckFamily() {
    XCTAssertEqual(MenuIcon.allCases, [.pocket, .peek, .buddy, .spark])
    XCTAssertEqual(MenuIcon.allCases.map(\.accessibilityLabel), ["Pocket", "Peek", "Buddy", "Spark"])
  }

  func testLegacyOptionsMigrateToPocket() {
    XCTAssertEqual(MenuIcon.maccy.migrated, .pocket)
    XCTAssertEqual(MenuIcon.clipboard.migrated, .pocket)
    XCTAssertEqual(MenuIcon.scissors.migrated, .pocket)
    XCTAssertEqual(MenuIcon.paperclip.migrated, .pocket)
  }

  func testTuckOptionsSurviveMigration() {
    for icon in MenuIcon.allCases {
      XCTAssertEqual(icon.migrated, icon)
    }
  }

  func testTuckAssetsAreTemplateImages() {
    for icon in MenuIcon.allCases {
      XCTAssertTrue(icon.image.isTemplate, "\(icon.accessibilityLabel) must render as a menu-bar template image")
    }
  }
}

final class ListStyleTests: XCTestCase {
  func testVisibleOptionsAreCuratedAndOrdered() {
    XCTAssertEqual(ListStyle.allCases, [.compact, .comfortable, .detailed])
  }

  func testStylesHaveDistinctUsefulLayouts() {
    XCTAssertEqual(ListStyle.compact.rowHeight, 28)
    XCTAssertEqual(ListStyle.comfortable.rowHeight, 32)
    XCTAssertEqual(ListStyle.detailed.rowHeight, 42)
    XCTAssertFalse(ListStyle.compact.showsDetails)
    XCTAssertFalse(ListStyle.comfortable.showsDetails)
    XCTAssertTrue(ListStyle.detailed.showsDetails)
  }

  func testStylesAlwaysHaveHumanReadableSettingsCopy() {
    XCTAssertFalse(ListStyle.settingsLabel.isEmpty)
    for style in ListStyle.allCases {
      XCTAssertFalse(style.title.isEmpty)
      XCTAssertFalse(style.settingsDescription.isEmpty)
      XCTAssertNotEqual(style.title, "ListStyle\(style.rawValue.capitalized)")
    }
  }

  func testListStylePreferenceRoundTrips() {
    let savedStyle = Defaults[.listStyle]
    defer { Defaults[.listStyle] = savedStyle }

    for style in ListStyle.allCases {
      Defaults[.listStyle] = style
      XCTAssertEqual(Defaults[.listStyle], style)
    }
  }
}

final class SettingsExperienceTests: XCTestCase {
  func testPrimaryNavigationOnlyContainsEverydayDestinations() {
    XCTAssertEqual(TuckSettingsDestination.allCases, [.general, .appearance, .privacy])
    XCTAssertEqual(
      TuckSettingsDestination.allCases.map(\.title),
      ["General", "Appearance", "Privacy & History"]
    )
  }

  func testPrimaryNavigationUsesDistinctNativeSymbols() {
    XCTAssertEqual(Set(TuckSettingsDestination.allCases.map(\.icon)).count, 3)
  }
}

final class DockWindowCoordinatorTests: XCTestCase {
  @MainActor
  func testDockRemainsUntilLastConventionalWindowCloses() async {
    var policies: [NSApplication.ActivationPolicy] = []
    var activationCount = 0
    let coordinator = DockWindowCoordinator(
      setActivationPolicy: {
        policies.append($0)
        return true
      },
      activateApplication: { activationCount += 1 }
    )
    let settingsWindow = NSWindow()
    let aboutWindow = NSWindow()

    coordinator.prepareForWindowPresentation()
    coordinator.track(settingsWindow)
    coordinator.prepareForWindowPresentation()
    coordinator.track(aboutWindow)

    XCTAssertEqual(policies, [.regular, .regular])
    XCTAssertEqual(activationCount, 2)

    NotificationCenter.default.post(name: NSWindow.willCloseNotification, object: settingsWindow)
    await Task.yield()
    XCTAssertEqual(policies, [.regular, .regular])

    NotificationCenter.default.post(name: NSWindow.willCloseNotification, object: aboutWindow)
    await Task.yield()
    XCTAssertEqual(policies, [.regular, .regular, .accessory])
  }

  @MainActor
  func testTrackingTheSameWindowTwiceDoesNotRequireTwoCloses() async {
    var policies: [NSApplication.ActivationPolicy] = []
    let coordinator = DockWindowCoordinator(
      setActivationPolicy: {
        policies.append($0)
        return true
      },
      activateApplication: {}
    )
    let settingsWindow = NSWindow()

    coordinator.prepareForWindowPresentation()
    coordinator.track(settingsWindow)
    coordinator.track(settingsWindow)
    NotificationCenter.default.post(name: NSWindow.willCloseNotification, object: settingsWindow)
    await Task.yield()

    XCTAssertEqual(policies, [.regular, .accessory])
  }
}
