import AppKit
import Defaults
import SwiftUI
import UniformTypeIdentifiers

struct StorageSettingsPane: View {
  @Observable
  class ViewModel {
    var saveFiles = false {
      didSet {
        Defaults.withoutPropagation {
          if saveFiles {
            Defaults[.enabledPasteboardTypes].formUnion(StorageType.files.types)
          } else {
            Defaults[.enabledPasteboardTypes].subtract(StorageType.files.types)
          }
        }
      }
    }

    var saveImages = false {
      didSet {
        Defaults.withoutPropagation {
          if saveImages {
            Defaults[.enabledPasteboardTypes].formUnion(StorageType.images.types)
          } else {
            Defaults[.enabledPasteboardTypes].subtract(StorageType.images.types)
          }
        }
      }
    }

    var saveText = false {
      didSet {
        Defaults.withoutPropagation {
          if saveText {
            Defaults[.enabledPasteboardTypes].formUnion(StorageType.text.types)
          } else {
            Defaults[.enabledPasteboardTypes].subtract(StorageType.text.types)
          }
        }
      }
    }

    private var observer: Defaults.Observation?

    init() {
      observer = Defaults.observe(.enabledPasteboardTypes) { change in
        self.saveFiles = change.newValue.isSuperset(of: StorageType.files.types)
        self.saveImages = change.newValue.isSuperset(of: StorageType.images.types)
        self.saveText = change.newValue.isSuperset(of: StorageType.text.types)
      }
    }

    deinit {
      observer?.invalidate()
    }
  }

  @Environment(AppState.self) private var appState

  @Default(.size) private var size
  @Default(.ignoredApps) private var ignoredApps

  @State private var viewModel = ViewModel()
  @State private var storageSize = Storage.shared.size
  @State private var addingIgnoredApp = false
  @State private var selectedIgnoredApp = ""
  @State private var showingClearConfirmation = false
  @State private var showingPins = false

  private let commonHistorySizes = [100, 200, 500, 999]

  var body: some View {
    TuckSettingsPage(
      title: "Privacy & History",
      subtitle: "Simple controls for what Tuck remembers—and what it never should."
    ) {
      HStack(spacing: 12) {
        Image(systemName: "lock.shield.fill")
          .font(.system(size: 22))
          .foregroundStyle(.tint)
        VStack(alignment: .leading, spacing: 2) {
          Text("Your clipboard history stays on this Mac")
            .font(.body.weight(.semibold))
          Text("Tuck has no account, cloud sync, analytics, or remote processing.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color.accentColor.opacity(0.08))
      .clipShape(.rect(cornerRadius: 13))

      TuckSettingsCard(title: "Don't remember from") {
        VStack(spacing: 0) {
          if ignoredApps.isEmpty {
            ContentUnavailableView(
              "No excluded apps",
              systemImage: "checkmark.shield",
              description: Text("Tuck currently remembers copies from every app.")
            )
            .frame(height: 115)
          } else {
            List(selection: $selectedIgnoredApp) {
              ForEach(ignoredApps, id: \.self) { app in
                ignoredAppLabel(app)
                  .tag(app)
              }
            }
            .listStyle(.inset)
            .frame(height: 140)
          }

          Divider()

          HStack {
            Button {
              addingIgnoredApp = true
            } label: {
              Label("Add App…", systemImage: "plus")
            }

            Button {
              removeIgnoredApp(selectedIgnoredApp)
            } label: {
              Label("Remove", systemImage: "minus")
            }
            .disabled(selectedIgnoredApp.isEmpty)

            Spacer()
            Text("Useful for password managers and private work apps.")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .padding(12)
        }
      }

      TuckSettingsCard(title: "Remember") {
        TuckSettingsRow(icon: "text.alignleft", title: "Text", subtitle: "Words, links, and rich text.") {
          Toggle("Text", isOn: $viewModel.saveText).labelsHidden()
        }
        TuckSettingsDivider()
        TuckSettingsRow(icon: "photo", title: "Images", subtitle: "Screenshots and copied images.") {
          Toggle("Images", isOn: $viewModel.saveImages).labelsHidden()
        }
        TuckSettingsDivider()
        TuckSettingsRow(icon: "doc", title: "Files", subtitle: "Files copied in Finder and other apps.") {
          Toggle("Files", isOn: $viewModel.saveFiles).labelsHidden()
        }
      }

      TuckSettingsCard(title: "History") {
        TuckSettingsRow(
          icon: "clock.arrow.circlepath",
          title: "History size",
          subtitle: storageSize.isEmpty ? "Choose how many recent items to keep." : "Using \(storageSize) on disk."
        ) {
          Picker("History size", selection: $size) {
            if !commonHistorySizes.contains(size) {
              Text("\(size) items").tag(size)
            }
            ForEach(commonHistorySizes, id: \.self) { count in
              Text("\(count) items").tag(count)
            }
          }
          .labelsHidden()
          .frame(width: 115)
        }

        TuckSettingsDivider()

        HStack {
          Button("Manage Pins…") {
            showingPins = true
          }
          Spacer()
          Button("Clear Unpinned History…", role: .destructive) {
            showingClearConfirmation = true
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
      }
    }
    .onAppear {
      storageSize = Storage.shared.size
    }
    .fileDialogDefaultDirectory(URL(fileURLWithPath: "/Applications", isDirectory: true))
    .fileImporter(isPresented: $addingIgnoredApp, allowedContentTypes: [.application]) { result in
      guard case .success(let appURL) = result,
            let bundleIdentifier = Bundle(path: appURL.path)?.bundleIdentifier,
            !ignoredApps.contains(bundleIdentifier) else { return }
      ignoredApps.append(bundleIdentifier)
      selectedIgnoredApp = bundleIdentifier
    }
    .alert("Clear unpinned history?", isPresented: $showingClearConfirmation) {
      Button("Cancel", role: .cancel) {}
      Button("Clear History", role: .destructive) {
        appState.history.clear()
        storageSize = Storage.shared.size
      }
    } message: {
      Text("Pinned items will stay in Tuck.")
    }
    .sheet(isPresented: $showingPins) {
      VStack(alignment: .leading, spacing: 0) {
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text("Pinned Items")
              .font(.title2.bold())
            Text("Edit shortcuts, titles, and plain-text content.")
              .foregroundStyle(.secondary)
          }
          Spacer()
          Button("Done") { showingPins = false }
            .keyboardShortcut(.defaultAction)
        }
        .padding([.horizontal, .top])

        PinsSettingsPane()
      }
      .frame(minWidth: 640, minHeight: 470)
    }
  }

  @ViewBuilder
  private func ignoredAppLabel(_ bundleIdentifier: String) -> some View {
    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
      Label {
        Text(NSWorkspace.shared.applicationName(url: url))
      } icon: {
        Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
      }
    } else {
      Label(bundleIdentifier, systemImage: "questionmark.app")
    }
  }

  private func removeIgnoredApp(_ bundleIdentifier: String) {
    guard !bundleIdentifier.isEmpty else { return }
    ignoredApps.removeAll(where: { $0 == bundleIdentifier })
    selectedIgnoredApp = ""
  }
}

#Preview {
  StorageSettingsPane()
    .environment(AppState.shared)
    .modelContainer(Storage.shared.container)
    .frame(width: 640, height: 720)
}
