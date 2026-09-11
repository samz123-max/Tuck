import AppKit
import Defaults

enum MenuIcon: String, CaseIterable, Identifiable, Defaults.Serializable {
  case pocket
  case peek
  case buddy
  case spark

  // Decode preferences written by earlier Maccy and Slipwell builds. These
  // compatibility cases are deliberately excluded from allCases.
  case maccy
  case clipboard
  case scissors
  case paperclip

  static let allCases: [MenuIcon] = [.pocket, .peek, .buddy, .spark]

  var id: Self { self }

  var image: NSImage {
    switch self {
    case .pocket:
      return NSImage(named: .tuckPocket)!
    case .peek:
      return NSImage(named: .tuckPeek)!
    case .buddy:
      return NSImage(named: .tuckBuddy)!
    case .spark:
      return NSImage(named: .tuckSpark)!
    case .maccy, .clipboard, .scissors, .paperclip:
      return NSImage(named: .tuckPocket)!
    }
  }

  var accessibilityLabel: String {
    switch self {
    case .pocket, .maccy, .clipboard, .scissors, .paperclip: return "Pocket"
    case .peek: return "Peek"
    case .buddy: return "Buddy"
    case .spark: return "Spark"
    }
  }

  var migrated: MenuIcon {
    switch self {
    case .pocket, .peek, .buddy, .spark:
      return self
    case .maccy, .clipboard, .scissors, .paperclip:
      return .pocket
    }
  }
}
