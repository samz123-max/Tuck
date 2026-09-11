import Defaults
import SwiftUI

struct HistoryItemView: View {
  @Bindable var item: HistoryItemDecorator
  var previous: HistoryItemDecorator?
  var next: HistoryItemDecorator?
  var index: Int

  private var selectionAppearance: SelectionAppearance {
    let previousSelected = previous?.isSelected ?? false
    let nextSelected = next?.isSelected ?? false
    switch (previousSelected, nextSelected) {
    case (true, false):
      return .topConnection
    case (false, true):
      return .bottomConnection
    case (true, true):
      return .topBottomConnection
    default:
      return .none
    }
  }

  @Default(.showHexColorSwatch) private var showHexColorSwatch
  @Default(.listStyle) private var listStyle
  @Environment(AppState.self) private var appState
  @State private var isHovering = false

  private var colorSwatchImage: NSImage? {
    guard showHexColorSwatch else { return nil }
    return ColorImage.from(item.title)
  }

  private var subtitle: String? {
    guard listStyle.showsDetails else { return nil }
    let relativeTime = item.item.lastCopiedAt.formatted(
      .relative(presentation: .named, unitsStyle: .abbreviated)
    )
    if let application = item.application {
      return "\(application) · \(relativeTime)"
    }
    return relativeTime
  }

  private func performSelect() {
    if NSEvent.modifierFlags.contains(.command) && appState.multiSelectionEnabled {
      appState.navigator.addToSelection(item: item)
    } else {
      let flags = NSEvent.ModifierFlags.currentModifierFlags
      Task {
        appState.history.select(item, flags: flags)
      }
    }
  }

  var body: some View {
    HStack(spacing: 0) {
      ListItemView(
        id: item.id,
        selectionId: item.id,
        appIcon: item.applicationImage,
        image: item.thumbnailImage,
        accessoryImage: item.thumbnailImage != nil ? nil : colorSwatchImage,
        attributedTitle: item.attributedTitle,
        shortcuts: item.shortcuts,
        isSelected: item.isSelected,
        selectionIndex: item.multiSelectionIndex,
        selectionAppearance: selectionAppearance,
        drawsSelectionBackground: false,
        style: listStyle,
        subtitle: subtitle,
        accessibilityLabel: item.accessibilityLabel
      ) {
        Text(verbatim: item.title)
      }
      .accessibilityIdentifier("copy-history-item")
      .buttonAction(performSelect)
      .onAppear {
        item.ensureThumbnailImage()
      }
      .accessibilityAction(named: Text(item.isPinned ? "history_item_unpin_action" : "history_item_pin_action")) {
        appState.history.togglePin(item)
      }
      .accessibilityAction(named: Text("history_item_delete_action")) {
        appState.history.delete(item)
      }
      Button {
        appState.navigator.select(item: item)
        appState.history.togglePin(item)
      } label: {
        Image(systemName: item.isPinned ? "pin.fill" : "pin")
          .font(.system(size: 12, weight: .medium))
          .frame(width: listStyle == .compact ? 28 : 30, height: listStyle.rowHeight)
          .contentShape(Rectangle())
      }
      .buttonStyle(.borderless)
      .foregroundStyle(item.isPinned ? Color.accentColor : Color.secondary)
      .opacity(isHovering || item.isSelected || item.isPinned ? 1 : 0)
      .accessibilityLabel(Text(item.isPinned ? "history_item_unpin_action" : "history_item_pin_action"))
      .help(item.isPinned ? "Unpin this item" : "Pin this item to keep it close")
    }
    .background(item.isSelected ? SelectionStyle.background : Color.clear)
    .overlay {
      selectionAppearance.rect(cornerRadius: Popup.cornerRadius)
        .stroke(item.isSelected ? SelectionStyle.border : Color.clear, lineWidth: 1)
    }
    .clipShape(selectionAppearance.rect(cornerRadius: Popup.cornerRadius))
    .padding(.horizontal, listStyle.rowInset)
    .contentShape(Rectangle())
    .onHover { isHovering = $0 }
  }
}
