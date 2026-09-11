import SwiftUI

enum AppIdentity {
  static let bundleIdentifier = "app.tuck.clipboard"
  static let legacyBundleIdentifier = "org.p0deje.Maccy"
  static var runtimeBundleIdentifier: String { Bundle.main.bundleIdentifier ?? bundleIdentifier }
}

@main
struct TuckApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  // It's impossible to create sceneless application,
  // so we are hacking this around by creating a menubar
  // scene that is always hidden.
  @State private var hiddenMenu: Bool = false

  var body: some Scene {
    MenuBarExtra("", isInserted: $hiddenMenu) {
      EmptyView()
    }
  }
}
