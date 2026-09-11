import Defaults
import SwiftUI

enum SelectionAppearance {
  case none
  case topConnection
  case bottomConnection
  case topBottomConnection

  func rect(cornerRadius: CGFloat) -> some Shape {
    var cornerRadii = RectangleCornerRadii()
    switch self {
    case .none:
      cornerRadii.topLeading = cornerRadius
      cornerRadii.topTrailing = cornerRadius
      cornerRadii.bottomLeading = cornerRadius
      cornerRadii.bottomTrailing = cornerRadius
    case .topConnection:
      cornerRadii.bottomLeading = cornerRadius
      cornerRadii.bottomTrailing = cornerRadius
    case .bottomConnection:
      cornerRadii.topLeading = cornerRadius
      cornerRadii.topTrailing = cornerRadius
    case .topBottomConnection:
      break
    }
    return .rect(cornerRadii: cornerRadii)
  }
}

enum SelectionStyle {
  static let foreground = Color.primary
  static let secondaryForeground = Color.secondary
  static let background = Color.accentColor.opacity(0.14)
  static let border = Color.accentColor.opacity(0.28)
}

struct ListItemView<Title: View, ID: Hashable>: View {
  var id: ID
  var selectionId: UUID
  var appIcon: ApplicationImage?
  var image: NSImage?
  var accessoryImage: NSImage?
  var attributedTitle: AttributedString?
  var shortcuts: [KeyShortcut]
  var isSelected: Bool
  var selectionIndex: Int?
  var help: LocalizedStringKey?
  var selectionAppearance: SelectionAppearance = .none
  var drawsSelectionBackground = true
  var style: ListStyle = .comfortable
  var subtitle: String?
  // Complete description used when the row's visual content is hidden from accessibility.
  var accessibilityLabel: String = ""
  @ViewBuilder var title: () -> Title

  @Default(.showApplicationIcons) private var showIcons
  @Environment(AppState.self) private var appState
  @Environment(ModifierFlags.self) private var modifierFlags

  // Use the same selection number for the visible badge and accessibility value.
  private var displaySelectionIndex: String? {
    selectionIndex.map { "\($0 + 1)" }
  }

  var body: some View {
    HStack(spacing: 0) {
      if showIcons, let appIcon {
        VStack {
          Spacer(minLength: 0)
          AppImageView(appImage: appIcon, size: NSSize(width: style.iconSize, height: style.iconSize))
          Spacer(minLength: 0)
        }
        .padding(.leading, 4)
        .padding(.vertical, style == .compact ? 5 : 6)
      }

      Spacer()
        .frame(width: showIcons ? style.contentSpacing : (style == .compact ? 10 : 12))

      if let accessoryImage {
        Image(nsImage: accessoryImage)
          .accessibilityIdentifier("copy-history-item")
          .accessibilityHidden(true)
          .padding(.trailing, style.contentSpacing)
          .padding(.vertical, style == .compact ? 5 : 6)
      }

      if let image {
        Image(nsImage: image)
          .accessibilityIdentifier("copy-history-item")
          .accessibilityHidden(true)
          .padding(.trailing, style.contentSpacing)
          .padding(.vertical, style == .compact ? 5 : 6)
        if let subtitle {
          Text(subtitle)
            .font(.caption2)
            .foregroundStyle(SelectionStyle.secondaryForeground)
            .lineLimit(1)
            .truncationMode(.tail)
            .accessibilityHidden(true)
            .padding(.trailing, style.titleTrailingPadding)
        }
      } else {
        VStack(alignment: .leading, spacing: 1) {
          ListItemTitleView(attributedTitle: attributedTitle, title: title)
          if let subtitle {
            Text(subtitle)
              .font(.caption2)
              .foregroundStyle(SelectionStyle.secondaryForeground)
              .lineLimit(1)
              .truncationMode(.tail)
          }
        }
        .accessibilityHidden(true)
        .padding(.trailing, style.titleTrailingPadding)
      }

      Spacer()

      HStack(spacing: style.contentSpacing) {
        if let displaySelectionIndex {
          Text(displaySelectionIndex)
            .font(.caption2.weight(.semibold))
            .frame(minWidth: 10, alignment: .center)
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(
              Color.primary.opacity(isSelected ? 0.1 : 0.07),
              in: Capsule()
            )
            .foregroundStyle(Color.secondary)
            .accessibilityHidden(true)
        }

        if !shortcuts.isEmpty {
          ZStack(alignment: .trailing) {
            ForEach(shortcuts) { shortcut in
              let visible = shortcut.isVisible(shortcuts, modifierFlags.flags)
              KeyboardShortcutView(shortcut: shortcut)
                .opacity(visible ? 1 : 0)
                .accessibilityHidden(true)
                .frame(width: visible ? nil : 0)
            }
          }
        }
      }
      .padding(.trailing, style.trailingPadding)
    }
    .frame(minHeight: style.rowHeight)
    .id(id)
    .frame(maxWidth: .infinity, alignment: .leading)
    .foregroundStyle(isSelected ? SelectionStyle.foreground : .primary)
    // macOS 26 broke hovering if no background is present.
    // The slight opcaity white background is a workaround
    .background(
      isSelected && drawsSelectionBackground
        ? SelectionStyle.background
        : .white.opacity(0.001)
    )
    .clipShape(selectionAppearance.rect(cornerRadius: Popup.cornerRadius))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(accessibilityLabel))
    .accessibilityAddTraits(isSelected ? .isSelected : [])
    .accessibilityValue(Text(displaySelectionIndex ?? ""))
    .hoverSelectionId(selectionId)
    .help(help ?? "")
  }
}
