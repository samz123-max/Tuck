import AppKit
import Defaults
import KeyboardShortcuts
import LaunchAtLogin
import SwiftUI

enum TuckSettingsDestination: String, CaseIterable, Identifiable {
  case general
  case appearance
  case privacy

  var id: Self { self }

  var title: String {
    switch self {
    case .general: "General"
    case .appearance: "Appearance"
    case .privacy: "Privacy & History"
    }
  }

  var icon: String {
    switch self {
    case .general: "gearshape"
    case .appearance: "paintpalette"
    case .privacy: "hand.raised"
    }
  }
}

struct GeneralSettingsPane: View {
  @State private var selection = TuckSettingsDestination.general
  @State private var showingAdvanced = false

  var body: some View {
    NavigationSplitView {
      VStack(spacing: 0) {
        HStack(spacing: 11) {
          Image(nsImage: NSApplication.shared.applicationIconImage)
            .resizable()
            .frame(width: 38, height: 38)

          VStack(alignment: .leading, spacing: 1) {
            Text("Tuck")
              .font(.headline)
            Text("A happy little home for everything you copy.")
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(2)
          }
        }
        .padding(.horizontal, 14)
        .padding(.top, 18)
        .padding(.bottom, 12)

        List(TuckSettingsDestination.allCases, selection: $selection) { destination in
          Label(destination.title, systemImage: destination.icon)
            .tag(destination)
            .padding(.vertical, 3)
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)

        Divider()

        Button {
          showingAdvanced = true
        } label: {
          Label("Advanced Settings…", systemImage: "slider.horizontal.3")
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .accessibilityIdentifier("advancedSettingsButton")
      }
      .navigationSplitViewColumnWidth(min: 190, ideal: 215, max: 235)
    } detail: {
      switch selection {
      case .general:
        TuckGeneralSettingsView()
      case .appearance:
        AppearanceSettingsPane()
      case .privacy:
        StorageSettingsPane()
      }
    }
    .navigationSplitViewStyle(.balanced)
    .sheet(isPresented: $showingAdvanced) {
      AdvancedSettingsPane()
    }
  }
}

struct TuckGeneralSettingsView: View {
  private let notificationsURL = URL(
    string: "x-apple.systempreferences:com.apple.preference.notifications?id=\(AppIdentity.runtimeBundleIdentifier)"
  )

  @State private var updater = SoftwareUpdater()
  @State private var showingAutomaticPasteRestartAlert = false
  @Default(.pasteByDefault) private var pasteByDefault

  var body: some View {
    TuckSettingsPage(
      title: "General",
      subtitle: "The essentials for a clipboard that is ready when you are."
    ) {
      TuckSettingsCard(title: "Everyday") {
        TuckSettingsRow(
          icon: "power",
          title: "Launch at login",
          subtitle: "Keep Tuck available after you sign in."
        ) {
          LaunchAtLogin.Toggle { EmptyView() }
            .labelsHidden()
        }

        TuckSettingsDivider()

        TuckSettingsRow(
          icon: "command",
          title: "Open Tuck",
          subtitle: "The shortcut you’ll use from anywhere."
        ) {
          KeyboardShortcuts.Recorder(for: .popup, onChange: { newShortcut in
            if newShortcut == nil {
              AppState.shared.popup.deinitEventsMonitor()
            } else {
              AppState.shared.popup.initEventsMonitor()
            }
          })
          .labelsHidden()
          .accessibilityLabel("Open Tuck shortcut")
        }

        TuckSettingsDivider()

        TuckSettingsRow(
          icon: pasteByDefault ? "arrow.down.doc.fill" : "hand.raised.fill",
          title: "Paste automatically",
          subtitle: pasteByDefault
            ? "Optional. Tuck sends ⌘V after you choose an item."
            : "Off by default. Choosing an item only copies it; press ⌘V yourself."
        ) {
          Defaults.Toggle(key: .pasteByDefault) { EmptyView() }
            .labelsHidden()
            .onChange(of: pasteByDefault) {
              guard pasteByDefault, !PostEventAccess.isGranted else { return }

              PostEventAccess.request()
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingAutomaticPasteRestartAlert = true
              }
            }
        }
      }

      TuckSettingsCard(title: "Updates & notifications") {
        TuckSettingsRow(
          icon: "arrow.triangle.2.circlepath",
          title: "Updates are installed manually",
          subtitle: "Automatic updates will arrive with a future public release."
        ) {
          Button("About this build…") {
            updater.checkForUpdates()
          }
        }

        if let notificationsURL {
          TuckSettingsDivider()

          TuckSettingsRow(
            icon: "bell",
            title: "Notifications & sounds",
            subtitle: "Choose how Tuck gets your attention."
          ) {
            Link("Open Settings", destination: notificationsURL)
          }
        }
      }
    }
    .alert(
      "Restart Tuck to Finish Setup",
      isPresented: $showingAutomaticPasteRestartAlert
    ) {
      Button("Restart Tuck") {
        restartTuck()
      }
      Button("Later", role: .cancel) {}
    } message: {
      Text(
        "After approving Automatic Paste in System Settings, restart Tuck so macOS applies the new permission. Copy-only mode continues to work without restarting."
      )
    }
  }

  private func restartTuck() {
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.activates = true
    configuration.createsNewApplicationInstance = true

    NSWorkspace.shared.openApplication(
      at: Bundle.main.bundleURL,
      configuration: configuration
    ) { _, error in
      DispatchQueue.main.async {
        if error == nil {
          NSApp.terminate(nil)
        } else {
          showingAutomaticPasteRestartAlert = true
        }
      }
    }
  }
}

struct TuckSettingsPage<Content: View>: View {
  let title: String
  let subtitle: String
  @ViewBuilder let content: Content

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 22) {
        VStack(alignment: .leading, spacing: 5) {
          Text(title)
            .font(.system(size: 26, weight: .bold, design: .rounded))
          Text(subtitle)
            .font(.body)
            .foregroundStyle(.secondary)
        }

        content
      }
      .frame(maxWidth: 680, alignment: .leading)
      .padding(.horizontal, 34)
      .padding(.top, 30)
      .padding(.bottom, 36)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(nsColor: .windowBackgroundColor))
  }
}

struct TuckSettingsCard<Content: View>: View {
  let title: String
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(title.uppercased())
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 8)

      content
    }
    .padding(.bottom, 4)
    .background(Color(nsColor: .controlBackgroundColor).opacity(0.72))
    .clipShape(.rect(cornerRadius: 13))
    .overlay {
      RoundedRectangle(cornerRadius: 13)
        .stroke(Color.secondary.opacity(0.14))
    }
  }
}

struct TuckSettingsRow<Control: View>: View {
  let icon: String
  let title: String
  let subtitle: String
  @ViewBuilder let control: Control

  var body: some View {
    HStack(spacing: 13) {
      Image(systemName: icon)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.tint)
        .frame(width: 30, height: 30)
        .background(Color.accentColor.opacity(0.11))
        .clipShape(.rect(cornerRadius: 8))

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.body.weight(.medium))
        Text(subtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 16)
      control
        .fixedSize()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 11)
  }
}

struct TuckSettingsDivider: View {
  var body: some View {
    Divider()
      .padding(.leading, 59)
  }
}

#Preview {
  GeneralSettingsPane()
    .environment(AppState.shared)
    .modelContainer(Storage.shared.container)
    .frame(width: 860, height: 620)
}
