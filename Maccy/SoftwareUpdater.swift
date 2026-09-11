import AppKit

@Observable
class SoftwareUpdater {
  // Display the original preference without changing it. Experimental releases
  // are installed manually and do not load an upstream network updater.
  var automaticallyChecksForUpdates = UserDefaults.standard.bool(forKey: "SUEnableAutomaticChecks")

  func checkForUpdates() {
    let alert = NSAlert()
    alert.messageText = "Tuck · Experimental"
    alert.informativeText = "Updates for this experiment are installed from a new Tuck disk image. Your clipboard history stays on this Mac."
    alert.addButton(withTitle: "Got it")
    alert.runModal()
  }
}
