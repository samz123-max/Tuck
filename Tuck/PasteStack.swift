import Foundation
import AppKit

@Observable
class PasteStack: Identifiable, Hashable {
  /// Paste-stack advancement previously watched Command-V system-wide. This
  /// permissionless experiment deliberately performs no global key monitoring.
  static func initializeIfNeeded() {
    // Intentionally empty.
  }

  var id: UUID = UUID()
  var items: [HistoryItemDecorator] = []
  var modifierFlags: NSEvent.ModifierFlags

  init(items: [HistoryItemDecorator], modifierFlags: NSEvent.ModifierFlags) {
    self.items = items
    self.modifierFlags = modifierFlags
  }

  static func == (lhs: PasteStack, rhs: PasteStack) -> Bool {
    return lhs.id == rhs.id
      && lhs.items == rhs.items
      && lhs.modifierFlags.rawValue == rhs.modifierFlags.rawValue
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(items)
    hasher.combine(modifierFlags.rawValue)
  }

}
