import Defaults
import SwiftUI

private struct FooterControl: View {
  @Bindable var item: FooterItem
  var systemImage: String?
  var showsTitle = false

  private func control(action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack(spacing: 6) {
        if let systemImage {
          Image(systemName: systemImage)
            .font(.system(size: 12, weight: .medium))
        }
        if showsTitle {
          Text(LocalizedStringKey(item.title))
            .font(.caption.weight(.medium))
        }
        if showsTitle, let shortcut = item.shortcuts.first {
          KeyboardShortcutView(shortcut: shortcut)
            .font(.caption2)
        }
      }
      .foregroundStyle(item.isSelected ? Color.primary : Color.secondary)
      .padding(.horizontal, showsTitle ? 9 : 0)
      .frame(minWidth: 28, minHeight: 27)
      .background(
        item.isSelected ? SelectionStyle.background : Color.clear,
        in: RoundedRectangle(cornerRadius: 8)
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(Text(LocalizedStringKey(item.title)))
    .help(item.help ?? "")
  }

  @ViewBuilder
  var body: some View {
    if let confirmation = item.confirmation,
       let suppressConfirmation = item.suppressConfirmation {
      control {
        if suppressConfirmation.wrappedValue {
          item.action()
        } else {
          item.showConfirmation = true
        }
      }
      .confirmationDialog(confirmation.message, isPresented: $item.showConfirmation) {
        Text(confirmation.comment)
        Button(confirmation.confirm, role: .destructive) {
          item.action()
        }
        .accessibilityIdentifier("confirmation-confirm")
        Button(confirmation.cancel, role: .cancel) {}
      }
      .dialogSuppressionToggle(isSuppressed: suppressConfirmation)
    } else {
      control(action: item.action)
    }
  }
}

struct FooterView: View {
  @Bindable var footer: Footer

  @Environment(AppState.self) private var appState
  @Environment(ModifierFlags.self) private var modifierFlags
  @Default(.showFooter) private var showFooter
  @State private var showClear = true
  @State private var showClearAll = false

  var clearAllModifiersPressed: Bool {
    let clearModifiers = footer.items[0].shortcuts.first?.modifierFlags ?? []
    let clearAllModifiers = footer.items[1].shortcuts.first?.modifierFlags ?? []
    return !modifierFlags.flags.isEmpty
      && !modifierFlags.flags.isSubset(of: clearModifiers)
      && modifierFlags.flags.isSubset(of: clearAllModifiers)
  }

  var body: some View {
    VStack(spacing: 0) {
      Divider()
        .padding(.horizontal, Popup.horizontalSeparatorPadding)
        .opacity(0.55)

      HStack(spacing: 4) {
        ZStack(alignment: .leading) {
          FooterControl(item: footer.items[0], systemImage: "trash", showsTitle: true)
            .invisible(!showClear)
          FooterControl(item: footer.items[1], systemImage: "trash.slash", showsTitle: true)
            .invisible(!showClearAll)
        }

        Spacer()

        FooterControl(item: footer.items[2], systemImage: "gearshape")
        FooterControl(item: footer.items[3], systemImage: "info.circle")
        FooterControl(item: footer.items[4], systemImage: "power")
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .onChange(of: modifierFlags.flags) {
        if clearAllModifiersPressed {
          showClear = false
          showClearAll = true
          footer.items[0].isVisible = false
          footer.items[1].isVisible = true
          if appState.footer.selectedItem == footer.items[0] {
            appState.navigator.select(footerItem: footer.items[1])
          }
        } else {
          showClear = true
          showClearAll = false
          footer.items[0].isVisible = true
          footer.items[1].isVisible = false
          if appState.footer.selectedItem == footer.items[1] {
            appState.navigator.select(footerItem: footer.items[0])
          }
        }
      }
    }
    .invisible(!showFooter)
    .frame(maxHeight: showFooter ? nil : 0)
    .readHeight(appState, into: \.popup.footerHeight)
  }
}
