import SwiftUI

struct PinsView: View {
  @Environment(AppState.self) private var appState

  var items: [HistoryItemDecorator]

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      HStack(spacing: 5) {
        Image(systemName: "pin.fill").accessibilityHidden(true)
        Text("Pinned")
        Spacer()
        Text("\(items.count)")
          .monospacedDigit()
          .padding(.horizontal, 7)
          .padding(.vertical, 2)
          .background(Color.primary.opacity(0.055), in: Capsule())
      }
      .font(.caption.weight(.semibold))
      .foregroundStyle(.secondary)
      .padding(.horizontal, 18)
      .padding(.vertical, 6)
      .help("Pinned items stay in your history until you unpin them.")
      MultipleSelectionListView(items: items) { previous, item, next, index in
        HistoryItemView(item: item, previous: previous, next: next, index: index)
      }
    }
  }
}
