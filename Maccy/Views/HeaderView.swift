import Defaults
import SwiftUI

struct HeaderView: View {
  @State private var appState = AppState.shared
  @Default(.showTitle) private var showTitle
  let controller: SlideoutController
  @FocusState.Binding var searchFocused: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if showTitle {
        HStack(spacing: 8) {
          Image(systemName: "tray.full.fill")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.tint)
            .frame(width: 24, height: 24)
            .background(Color.accentColor.opacity(0.12), in: Circle())
            .accessibilityHidden(true)

          Text("Tuck")
            .font(.system(size: 16, weight: .semibold, design: .rounded))

          Text("Clipboard")
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.primary.opacity(0.06), in: Capsule())

          Spacer()
        }
      }
      HStack(spacing: 10) {
        ListHeaderView(searchFocused: $searchFocused, searchQuery: $appState.history.searchQuery)
        ToolbarButton { controller.togglePreview() } label: {
          Image(systemName: controller.placement == .right ? "sidebar.right" : "sidebar.left")
            .font(.system(size: 15))
            .frame(width: 34, height: 34)
            .background(
              Color.primary.opacity(controller.state.isOpen ? 0.1 : 0.055),
              in: RoundedRectangle(cornerRadius: 10)
            )
        }
        .shortcutKeyHelp(name: .togglePreview,
                         key: controller.state.isOpen ? "ClosePreview" : "OpenPreview",
                         tableName: "PreviewItemView", replacementKey: "previewKey")
        .accessibilityLabel(controller.state.isOpen ? "Close preview" : "Open preview")
      }
      .opacity(appState.searchVisible ? 1 : 0)
      .accessibilityHidden(!appState.searchVisible)
      .frame(maxHeight: appState.searchVisible ? nil : 0, alignment: .top)
      .clipped()
      HStack(spacing: 6) {
        ForEach(ClipboardCategory.allCases) { category in
          Button {
            appState.history.category = category
            searchFocused = true
          } label: {
            Text(LocalizedStringKey(category.rawValue))
              .font(.caption.weight(appState.history.category == category ? .semibold : .medium))
              .foregroundStyle(appState.history.category == category ? Color.primary : Color.secondary)
              .padding(.horizontal, 11)
              .frame(height: 26)
              .background(
                appState.history.category == category
                  ? Color.accentColor.opacity(0.16)
                  : Color.primary.opacity(0.045),
                in: Capsule()
              )
          }
          .buttonStyle(.plain)
          .accessibilityAddTraits(appState.history.category == category ? .isSelected : [])
        }

        Spacer(minLength: 0)
      }
      .accessibilityIdentifier("clipboard-type-filter")
    }
    .padding(.horizontal, 18)
    .padding(.top, 16)
    .padding(.bottom, 10)
    .readHeight(appState, into: \.popup.headerHeight)
  }
}
