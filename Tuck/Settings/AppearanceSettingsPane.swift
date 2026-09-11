import AppKit
import Defaults
import SwiftUI

struct AppearanceSettingsPane: View {
  @Default(.popupPosition) private var popupAt
  @Default(.popupScreen) private var popupScreen
  @Default(.listStyle) private var listStyle
  @Default(.menuIcon) private var menuIcon

  @State private var screens = NSScreen.screens

  var body: some View {
    TuckSettingsPage(
      title: "Appearance",
      subtitle: "Make Tuck feel at home without getting lost in details."
    ) {
      TuckSettingsCard(title: "Clipboard list") {
        VStack(alignment: .leading, spacing: 12) {
          Picker("List style", selection: $listStyle) {
            ForEach(ListStyle.allCases) { style in
              Text(style.title).tag(style)
            }
          }
          .pickerStyle(.segmented)
          .labelsHidden()
          .accessibilityLabel("List style")

          ListStylePreview(style: listStyle)

          Text(listStyle.settingsDescription)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
      }

      TuckSettingsCard(title: "Menu bar") {
        TuckSettingsRow(
          icon: "menubar.rectangle",
          title: "Tuck icon",
          subtitle: "Choose the little companion that lives in your menu bar."
        ) {
          Picker("Tuck icon", selection: $menuIcon) {
            ForEach(MenuIcon.allCases) { icon in
              Image(nsImage: icon.image)
                .accessibilityLabel(Text(icon.accessibilityLabel))
                .tag(icon)
            }
          }
          .labelsHidden()
          .controlSize(.small)
          .frame(width: 150)
        }
      }

      TuckSettingsCard(title: "Window") {
        TuckSettingsRow(
          icon: "macwindow",
          title: "Show Tuck at",
          subtitle: "Where the clipboard opens."
        ) {
          Picker("Show Tuck at", selection: $popupAt) {
            ForEach(PopupPosition.allCases) { position in
              if position == .center || position == .lastPosition, screens.count > 1 {
                screenPicker(for: position)
              } else {
                Text(position.description)
              }
            }
          }
          .labelsHidden()
          .frame(width: 155)
        }

        TuckSettingsDivider()

        TuckSettingsRow(
          icon: "rectangle.on.rectangle",
          title: "Open previews automatically",
          subtitle: "Show a larger preview after a short pause."
        ) {
          Defaults.Toggle(key: .openPreviewAutomatically) { EmptyView() }
            .labelsHidden()
        }
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
      screens = NSScreen.screens
    }
  }

  @ViewBuilder
  private func screenPicker(for position: PopupPosition) -> some View {
    let screenBinding = Binding<Int> {
      popupScreen
    } set: {
      popupScreen = $0
      popupAt = position
    }

    Picker(selection: screenBinding) {
      Text(labelForScreen(index: 0)).tag(0)
      ForEach(screens.indices, id: \.self) { index in
        Text(labelForScreen(index: index + 1)).tag(index + 1)
      }
    } label: {
      if popupAt == position {
        Text("\(position.description) (\(labelForScreen(index: popupScreen)))")
      } else {
        Text(position.description)
      }
    }
  }

  private func labelForScreen(index screenIndex: Int) -> String {
    switch screenIndex {
    case 0:
      String(localized: "ActiveScreen", table: "AppearanceSettings")
    default:
      screens[screenIndex - 1].localizedName
    }
  }
}

private struct ListStylePreview: View {
  let style: ListStyle

  var body: some View {
    VStack(spacing: 0) {
      sampleRow(title: "Project notes", detail: "Notes · 2 min ago", icon: "note.text", selected: true)
      sampleRow(title: "A useful link for later", detail: "Safari · 8 min ago", icon: "safari", selected: false)
    }
    .padding(6)
    .background(Color(nsColor: .windowBackgroundColor).opacity(0.7))
    .clipShape(.rect(cornerRadius: 10))
    .overlay {
      RoundedRectangle(cornerRadius: 10)
        .stroke(Color.secondary.opacity(0.12))
    }
    .accessibilityHidden(true)
  }

  private func sampleRow(title: String, detail: String, icon: String, selected: Bool) -> some View {
    HStack(spacing: style.contentSpacing) {
      Image(systemName: icon)
        .font(.system(size: style.iconSize - 2))
        .frame(width: style.iconSize, height: style.iconSize)

      VStack(alignment: .leading, spacing: 1) {
        Text(title).lineLimit(1)
        if style.showsDetails {
          Text(detail)
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }

      Spacer(minLength: 8)
      Text("⌘1")
        .font(.caption2.monospacedDigit())
        .foregroundStyle(.secondary)
      Image(systemName: "pin")
        .font(.system(size: 11, weight: .medium))
    }
    .padding(.horizontal, style == .compact ? 8 : 10)
    .frame(height: style.rowHeight)
    .foregroundStyle(.primary)
    .background(selected ? SelectionStyle.background : Color.clear)
    .overlay {
      RoundedRectangle(cornerRadius: Popup.cornerRadius)
        .stroke(selected ? SelectionStyle.border : Color.clear, lineWidth: 1)
    }
    .clipShape(.rect(cornerRadius: Popup.cornerRadius))
    .padding(.horizontal, style.rowInset == 0 ? 0 : 4)
  }
}

#Preview {
  AppearanceSettingsPane()
    .frame(width: 640, height: 620)
}
