import Defaults
import KeyboardShortcuts
import SwiftUI

private enum AdvancedSettingsSection: String, CaseIterable, Identifiable {
  case behavior
  case interface
  case shortcuts
  case rules

  var id: Self { self }

  var title: String {
    switch self {
    case .behavior: "Behaviour"
    case .interface: "Interface"
    case .shortcuts: "Shortcuts"
    case .rules: "Rules & Automation"
    }
  }

  var icon: String {
    switch self {
    case .behavior: "switch.2"
    case .interface: "rectangle.3.group"
    case .shortcuts: "command"
    case .rules: "curlybraces"
    }
  }
}

private enum AdvancedRuleEditor: String, Identifiable {
  case pasteboardTypes
  case regularExpressions

  var id: String { rawValue }
}

struct AdvancedSettingsPane: View {
  @Environment(\.dismiss) private var dismiss

  @Default(.searchMode) private var searchMode
  @Default(.sortBy) private var sortBy
  @Default(.pinTo) private var pinTo
  @Default(.size) private var historySize
  @Default(.highlightMatch) private var highlightMatch
  @Default(.imageMaxHeight) private var imageHeight
  @Default(.previewDelay) private var previewDelay
  @Default(.searchVisibility) private var searchVisibility
  @Default(.showSearch) private var showSearch

  @State private var selection = AdvancedSettingsSection.behavior
  @State private var ruleEditor: AdvancedRuleEditor?

  private let integerFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimum = 1
    formatter.maximum = 100_000
    return formatter
  }()

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Advanced Settings")
            .font(.headline)
          Text("Fine-tune Tuck’s behaviour and compatibility.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
        Button("Done") { dismiss() }
          .keyboardShortcut(.defaultAction)
      }
      .padding(.horizontal, 18)
      .padding(.vertical, 13)

      Divider()

      NavigationSplitView {
        List(AdvancedSettingsSection.allCases, selection: $selection) { section in
          Label(section.title, systemImage: section.icon)
            .tag(section)
            .padding(.vertical, 2)
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 170, ideal: 185, max: 205)
      } detail: {
        switch selection {
        case .behavior:
          behaviorPage
        case .interface:
          interfacePage
        case .shortcuts:
          shortcutsPage
        case .rules:
          rulesPage
        }
      }
      .navigationSplitViewStyle(.balanced)
    }
    .frame(width: 790, height: 590)
    .sheet(item: $ruleEditor) { editor in
      VStack(alignment: .leading, spacing: 0) {
        HStack {
          Text(editor == .pasteboardTypes ? "Pasteboard Types" : "Regular Expressions")
            .font(.title2.bold())
          Spacer()
          Button("Done") { ruleEditor = nil }
            .keyboardShortcut(.defaultAction)
        }
        .padding([.horizontal, .top])

        if editor == .pasteboardTypes {
          IgnorePasteboardTypesSettingsView()
        } else {
          IgnoreRegexpsSettingsView()
        }
      }
      .frame(minWidth: 560, minHeight: 430)
    }
  }

  private var behaviorPage: some View {
    TuckSettingsPage(title: "Behaviour", subtitle: "Specialist controls for how Tuck stores and selects items.") {
      TuckSettingsCard(title: "Finding & ordering") {
        TuckSettingsRow(icon: "magnifyingglass", title: "Search matching", subtitle: "Choose the matching algorithm.") {
          Picker("Search matching", selection: $searchMode) {
            ForEach(Search.Mode.allCases) { mode in
              Text(mode.description)
            }
          }
          .labelsHidden()
          .frame(width: 150)
        }
        TuckSettingsDivider()
        TuckSettingsRow(icon: "arrow.up.arrow.down", title: "Sort history by", subtitle: "The order used in the clipboard list.") {
          Picker("Sort history by", selection: $sortBy) {
            ForEach(Sorter.By.allCases) { mode in
              Text(mode.description)
            }
          }
          .labelsHidden()
          .frame(width: 160)
        }
        TuckSettingsDivider()
        TuckSettingsRow(icon: "pin", title: "Pinned items", subtitle: "Place pins above or below recent history.") {
          Picker("Pinned items", selection: $pinTo) {
            ForEach(PinsPosition.allCases) { position in
              Text(position.description)
            }
          }
          .labelsHidden()
          .frame(width: 100)
        }
      }

      TuckSettingsCard(title: "Clipboard") {
        TuckSettingsRow(icon: "textformat", title: "Paste without formatting", subtitle: "Use plain text as the default paste action.") {
          Defaults.Toggle(key: .removeFormattingByDefault) { EmptyView() }
            .labelsHidden()
        }
        TuckSettingsDivider()
        TuckSettingsRow(icon: "number", title: "Custom history limit", subtitle: "Keep between 1 and 999 items.") {
          HStack(spacing: 6) {
            TextField("", value: $historySize, formatter: integerFormatter)
              .frame(width: 58)
            Stepper("", value: $historySize, in: 1...999)
              .labelsHidden()
          }
        }
        TuckSettingsDivider()
        TuckSettingsRow(icon: "trash", title: "Clear history on quit", subtitle: "Pinned items are preserved.") {
          Defaults.Toggle(key: .clearOnQuit) { EmptyView() }
            .labelsHidden()
        }
        TuckSettingsDivider()
        TuckSettingsRow(icon: "clipboard", title: "Clear the system clipboard too", subtitle: "Also clear the current macOS clipboard.") {
          Defaults.Toggle(key: .clearSystemClipboard) { EmptyView() }
            .labelsHidden()
        }
      }
    }
  }

  private var interfacePage: some View {
    TuckSettingsPage(title: "Interface", subtitle: "Detailed presentation controls for particular workflows.") {
      TuckSettingsCard(title: "Menu bar & window") {
        advancedToggle(.showInStatusBar, icon: "menubar.rectangle", title: "Show menu-bar icon")
        TuckSettingsDivider()
        advancedToggle(.showRecentCopyInMenuBar, icon: "text.append", title: "Show recent copy beside the icon")
        TuckSettingsDivider()
        advancedToggle(.showTitle, icon: "character.textbox", title: "Show Tuck heading and tagline")
        TuckSettingsDivider()
        advancedToggle(.showFooter, icon: "rectangle.bottomthird.inset.filled", title: "Show footer")
      }

      TuckSettingsCard(title: "Clipboard content") {
        advancedToggle(.showApplicationIcons, icon: "app", title: "Show source-application icons")
        TuckSettingsDivider()
        advancedToggle(.showHexColorSwatch, icon: "paintpalette", title: "Show hexadecimal colour swatches")
        TuckSettingsDivider()
        advancedToggle(.showSpecialSymbols, icon: "paragraphsign", title: "Show whitespace symbols")
      }

      TuckSettingsCard(title: "Search & previews") {
        TuckSettingsRow(icon: "magnifyingglass", title: "Search field", subtitle: "Choose when the search field appears.") {
          HStack(spacing: 8) {
            Toggle("", isOn: $showSearch).labelsHidden()
            Picker("Search field", selection: $searchVisibility) {
              ForEach(SearchVisibility.allCases) { visibility in
                Text(visibility.description)
              }
            }
            .labelsHidden()
            .disabled(!showSearch)
            .frame(width: 115)
          }
        }
        TuckSettingsDivider()
        TuckSettingsRow(icon: "highlighter", title: "Highlight matches", subtitle: "Style matching text in search results.") {
          Picker("Highlight matches", selection: $highlightMatch) {
            ForEach(HighlightMatch.allCases) { match in
              Text(match.description)
            }
          }
          .labelsHidden()
          .frame(width: 110)
        }
        TuckSettingsDivider()
        numberRow(icon: "photo", title: "Maximum image height", value: $imageHeight, range: 1...200, suffix: "pt")
        TuckSettingsDivider()
        numberRow(icon: "timer", title: "Preview delay", value: $previewDelay, range: 200...100_000, suffix: "ms")
      }
    }
  }

  private var shortcutsPage: some View {
    TuckSettingsPage(title: "Shortcuts", subtitle: "Optional keyboard controls beyond opening Tuck.") {
      TuckSettingsCard(title: "Item actions") {
        shortcutRow(icon: "pin", title: "Pin or unpin", name: .pin)
        TuckSettingsDivider()
        shortcutRow(icon: "trash", title: "Delete item", name: .delete)
        TuckSettingsDivider()
        shortcutRow(icon: "rectangle.on.rectangle", title: "Show preview", name: .togglePreview)
      }

      Text("Most people only need the Open Tuck shortcut in General. These shortcuts are available for faster keyboard-driven workflows.")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  private var rulesPage: some View {
    TuckSettingsPage(title: "Rules & Automation", subtitle: "Compatibility tools for apps and scripted workflows.") {
      TuckSettingsCard(title: "Capture rules") {
        TuckSettingsRow(icon: "list.bullet.clipboard", title: "Pasteboard types", subtitle: "Ignore application-specific clipboard formats.") {
          Button("Edit…") { ruleEditor = .pasteboardTypes }
        }
        TuckSettingsDivider()
        TuckSettingsRow(icon: "textformat.abc.dottedunderline", title: "Regular expressions", subtitle: "Ignore copied text that matches a pattern.") {
          Button("Edit…") { ruleEditor = .regularExpressions }
        }
        TuckSettingsDivider()
        TuckSettingsRow(icon: "checklist", title: "Treat excluded apps as an allow-list", subtitle: "Remember only copies from apps listed in Privacy.") {
          Defaults.Toggle(key: .ignoreAllAppsExceptListed) { EmptyView() }
            .labelsHidden()
        }
      }

      TuckSettingsCard(title: "Temporary pause") {
        TuckSettingsRow(icon: "pause.circle", title: "Pause clipboard capture", subtitle: "Temporarily ignore all new copies.") {
          Defaults.Toggle(key: .ignoreEvents) { EmptyView() }
            .labelsHidden()
        }

        DisclosureGroup("Command-line automation") {
          VStack(alignment: .leading, spacing: 10) {
            Text("TurnOffShellScript", tableName: "AdvancedSettings")
            Text("TurnOffNextShellScript", tableName: "AdvancedSettings")
          }
          .font(.system(size: 11, design: .monospaced))
          .foregroundStyle(.secondary)
          .textSelection(.enabled)
          .padding(.top, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
      }
    }
  }

  private func advancedToggle(
    _ key: Defaults.Key<Bool>,
    icon: String,
    title: String
  ) -> some View {
    TuckSettingsRow(icon: icon, title: title, subtitle: "") {
      Defaults.Toggle(key: key) { EmptyView() }
        .labelsHidden()
    }
  }

  private func shortcutRow(icon: String, title: String, name: KeyboardShortcuts.Name) -> some View {
    TuckSettingsRow(icon: icon, title: title, subtitle: "") {
      KeyboardShortcuts.Recorder(for: name)
        .labelsHidden()
        .accessibilityLabel(title)
    }
  }

  private func numberRow(
    icon: String,
    title: String,
    value: Binding<Int>,
    range: ClosedRange<Int>,
    suffix: String
  ) -> some View {
    TuckSettingsRow(icon: icon, title: title, subtitle: "") {
      HStack(spacing: 6) {
        TextField("", value: value, formatter: integerFormatter)
          .frame(width: 66)
        Text(suffix)
          .font(.caption)
          .foregroundStyle(.secondary)
        Stepper("", value: value, in: range)
          .labelsHidden()
      }
    }
  }
}

#Preview {
  AdvancedSettingsPane()
}
