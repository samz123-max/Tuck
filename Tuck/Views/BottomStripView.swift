import Defaults
import SwiftUI

struct BottomStripView: View {
  @FocusState.Binding var searchFocused: Bool

  @State private var appState = AppState.shared
  @Environment(ModifierFlags.self) private var modifierFlags
  @Environment(\.scenePhase) private var scenePhase
  @Default(.pinTo) private var pinTo

  var body: some View {
    let pinnedItems = appState.history.pinnedItems.filter(\.isVisible)
    let unpinnedItems = appState.history.unpinnedItems.filter(\.isVisible)

    VStack(spacing: 0) {
      chrome(resultCount: pinnedItems.count + unpinnedItems.count)

      Divider()
        .opacity(0.38)

      cardRail(pinnedItems: pinnedItems, unpinnedItems: unpinnedItems)
    }
    .onAppear {
      searchFocused = true
      activateSelection()
    }
    .onChange(of: scenePhase) {
      if scenePhase == .active {
        searchFocused = true
        activateSelection()
      } else {
        modifierFlags.flags = []
        appState.navigator.isKeyboardNavigating = true
        appState.preview.cancelAutoOpen()
      }
    }
    .onMouseMove {
      appState.navigator.isKeyboardNavigating = false
    }
  }

  private func chrome(resultCount: Int) -> some View {
    HStack(spacing: 12) {
      HStack(spacing: 8) {
        Image(systemName: "tray.full.fill")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(.tint)
          .frame(width: 26, height: 26)
          .background(Color.accentColor.opacity(0.13), in: Circle())
          .accessibilityHidden(true)

        Text("Tuck")
          .font(.system(size: 15, weight: .semibold, design: .rounded))
      }

      ListHeaderView(
        searchFocused: $searchFocused,
        searchQuery: $appState.history.searchQuery
      )
      .frame(minWidth: 230, idealWidth: 360, maxWidth: 430)

      HStack(spacing: 5) {
        ForEach(ClipboardCategory.allCases) { category in
          Button {
            appState.history.category = category
            searchFocused = true
          } label: {
            Text(LocalizedStringKey(category.rawValue))
              .font(.caption.weight(appState.history.category == category ? .semibold : .medium))
              .foregroundStyle(appState.history.category == category ? Color.primary : Color.secondary)
              .padding(.horizontal, 10)
              .frame(height: 28)
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
      }
      .accessibilityIdentifier("clipboard-type-filter")

      Spacer(minLength: 0)

      Button {
        appState.preview.togglePreview()
      } label: {
        Image(systemName: appState.preview.state.isOpen ? "rectangle.on.rectangle.slash" : "rectangle.on.rectangle")
          .font(.system(size: 13, weight: .medium))
          .frame(width: 30, height: 30)
          .background(
            appState.preview.state.isOpen ? Color.accentColor.opacity(0.16) : Color.primary.opacity(0.045),
            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
          )
      }
      .buttonStyle(.plain)
      .help(appState.preview.state.isOpen ? "Close preview (Space)" : "Preview selected card (Space)")
      .accessibilityLabel(appState.preview.state.isOpen ? "Close preview" : "Preview selected card")
      .disabled(appState.navigator.leadHistoryItem == nil)

      Text("\(resultCount)")
        .font(.caption.monospacedDigit().weight(.medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 9)
        .frame(height: 26)
        .background(Color.primary.opacity(0.05), in: Capsule())
        .accessibilityLabel("\(resultCount) clipboard items")

      Menu {
        Button("Settings…") {
          appState.openPreferences()
        }
      } label: {
        Image(systemName: "ellipsis")
          .font(.system(size: 14, weight: .semibold))
          .frame(width: 30, height: 30)
          .contentShape(Rectangle())
      }
      .menuStyle(.borderlessButton)
      .menuIndicator(.hidden)
      .fixedSize()
      .accessibilityLabel("More options")

      Divider()
        .frame(height: 18)
        .opacity(0.45)

      Button {
        NSApp.terminate(nil)
      } label: {
        Image(systemName: "power")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(.secondary)
          .frame(width: 30, height: 30)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .help("Quit Tuck")
      .accessibilityLabel("Quit Tuck")
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 11)
  }

  private func cardRail(
    pinnedItems: [HistoryItemDecorator],
    unpinnedItems: [HistoryItemDecorator]
  ) -> some View {
    ScrollView(.horizontal) {
      ScrollViewReader { proxy in
        LazyHStack(spacing: 10) {
          if pinTo == .top {
            cards(pinnedItems)
            sectionDividerIfNeeded(
              hasPinnedItems: !pinnedItems.isEmpty,
              hasUnpinnedItems: !unpinnedItems.isEmpty
            )
          }

          cards(unpinnedItems)

          if pinTo == .bottom {
            sectionDividerIfNeeded(
              hasPinnedItems: !pinnedItems.isEmpty,
              hasUnpinnedItems: !unpinnedItems.isEmpty
            )
            cards(pinnedItems)
          }

          if pinnedItems.isEmpty && unpinnedItems.isEmpty {
            emptyState
          }
        }
        .scrollTargetLayout()
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .task(id: appState.navigator.scrollTarget) {
          guard let target = appState.navigator.scrollTarget else { return }
          try? await Task.sleep(for: .milliseconds(10))
          guard !Task.isCancelled else { return }
          withAnimation(.easeOut(duration: 0.18)) {
            proxy.scrollTo(target)
          }
          appState.navigator.scrollTarget = nil
        }
      }
    }
    .scrollIndicators(.visible)
    .accessibilityIdentifier("bottom-strip-card-rail")
  }

  @ViewBuilder
  private func cards(_ items: [HistoryItemDecorator]) -> some View {
    ForEach(items) { item in
      BottomStripCard(item: item)
        .id(item.id)
        .onAppear {
          prefetchCardImages(around: item, in: items)
        }
    }
  }

  private func prefetchCardImages(
    around item: HistoryItemDecorator,
    in items: [HistoryItemDecorator]
  ) {
    guard let index = items.firstIndex(of: item) else { return }

    let lowerBound = max(items.startIndex, index - 1)
    let upperBound = min(items.index(before: items.endIndex), index + 3)
    for candidate in items[lowerBound...upperBound] where candidate.category == .images {
      candidate.ensureCardImage()
    }
  }

  @ViewBuilder
  private func sectionDividerIfNeeded(
    hasPinnedItems: Bool,
    hasUnpinnedItems: Bool
  ) -> some View {
    if hasPinnedItems && hasUnpinnedItems {
      VStack(spacing: 7) {
        Image(systemName: "pin.fill")
          .font(.caption)
        Capsule()
          .fill(Color.primary.opacity(0.12))
          .frame(width: 1.5, height: 88)
      }
      .foregroundStyle(.tertiary)
      .frame(width: 15)
      .accessibilityHidden(true)
    }
  }

  private var emptyState: some View {
    HStack(spacing: 12) {
      Image(systemName: appState.history.searchQuery.isEmpty ? "tray.full" : "magnifyingglass")
        .font(.system(size: 24, weight: .light))
        .foregroundStyle(.tint)

      VStack(alignment: .leading, spacing: 3) {
        Text(appState.history.searchQuery.isEmpty ? "Ready when you copy" : "Nothing found")
          .font(.headline)
        Text(appState.history.searchQuery.isEmpty
          ? "Clipboard items will appear here."
          : "Try another word or clear your search.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .frame(minWidth: 360, maxHeight: .infinity, alignment: .leading)
    .padding(.horizontal, 28)
  }

  private func activateSelection() {
    appState.navigator.isKeyboardNavigating = true
    if appState.navigator.leadHistoryItem?.isVisible != true {
      let firstUnpinnedItem = appState.history.unpinnedItems.first(where: \.isVisible)
      let firstPinnedItem = appState.history.pinnedItems.first(where: \.isVisible)
      appState.navigator.select(item: firstUnpinnedItem ?? firstPinnedItem)
    }
    appState.preview.cancelAutoOpen()
    appState.preview.state = .closed
  }
}

struct BottomStripPreviewSurface: View {
  @State private var appState = AppState.shared
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @Environment(\.colorSchemeContrast) private var contrast

  var body: some View {
    ZStack {
      if reduceTransparency || contrast == .increased {
        Color(nsColor: .windowBackgroundColor)
      } else if #available(macOS 26.0, *) {
        GlassEffectView()
      } else {
        VisualEffectView(material: .popover, blendingMode: .behindWindow)
      }

      VStack(spacing: 12) {
        ToolbarView()

        if let item = appState.navigator.leadHistoryItem {
          PreviewItemView(item: item)
        }
      }
      .padding(.horizontal, 18)
      .padding(.top, 16)
      .padding(.bottom, 18)
    }
    .environment(appState)
  }
}

private struct BottomStripCard: View {
  @Bindable var item: HistoryItemDecorator

  @State private var appState = AppState.shared
  @State private var appBandAccentColor = NSColor.controlAccentColor
  @State private var isHovering = false

  private enum Kind {
    case image, file, link, color, text
  }

  private var colorImage: NSImage? {
    item.cardColorImage
  }

  private var kind: Kind {
    if !item.fileURLs.isEmpty { return .file }
    if item.category == .images { return .image }
    if item.category == .links { return .link }
    if colorImage != nil { return .color }
    return .text
  }

  private var kindLabel: String {
    switch kind {
    case .image: "Image"
    case .file: item.fileURLs.count == 1 ? "File" : "Files"
    case .link: "Link"
    case .color: "Color"
    case .text: "Text"
    }
  }

  private var kindSymbol: String {
    switch kind {
    case .image: "photo"
    case .file: "doc"
    case .link: "link"
    case .color: "paintpalette"
    case .text: "text.alignleft"
    }
  }

  private var relativeTime: String {
    item.item.lastCopiedAt.formatted(.relative(presentation: .named, unitsStyle: .abbreviated))
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 9) {
        HStack(spacing: 7) {
          Label(kindLabel, systemImage: kindSymbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(item.isSelected ? Color.accentColor : Color.secondary)
            .lineLimit(1)

          Spacer(minLength: 4)

          Text(relativeTime)
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .lineLimit(1)

          if item.isPinned {
            Image(systemName: "pin.fill")
              .font(.caption2)
              .foregroundStyle(.tint)
              .accessibilityHidden(true)
          }
        }

        cardContent
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }
      .padding(12)
      .padding(.bottom, 2)

      sourceAppBand
    }
    .frame(width: 220, height: 228)
    .background(cardBackground, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 15, style: .continuous)
        .strokeBorder(
          item.isSelected ? Color.accentColor : Color.primary.opacity(isHovering ? 0.16 : 0.085),
          lineWidth: item.isSelected ? 2 : 1
        )
    }
    .shadow(color: .black.opacity(item.isSelected ? 0.12 : 0.055), radius: item.isSelected ? 8 : 4, y: 2)
    .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    // Keep selection responsive on the first click. Making these gestures
    // exclusive delays the single-click action until macOS's double-click
    // interval has elapsed.
    .onTapGesture(count: 2, perform: performPrimaryAction)
    .simultaneousGesture(
      TapGesture(count: 1)
        .onEnded { selectCard() }
    )
    .accessibilityAddTraits(.isButton)
    .accessibilityAction(.default, selectCard)
    .help("Click to select. Double-click to copy or paste.")
    .onHover { isHovering = $0 }
    .task(id: item.applicationImage.bundleIdentifier) {
      appBandAccentColor = await item.applicationImage.resolvedAccentColor()
    }
    .contextMenu {
      Button(item.isPinned ? "Unpin" : "Pin") {
        appState.navigator.select(item: item)
        appState.history.togglePin(item)
      }
      Divider()
      Button("Delete", role: .destructive) {
        appState.history.delete(item)
      }
    }
    .accessibilityIdentifier("bottom-strip-card")
    .accessibilityLabel(item.accessibilityLabel)
    .accessibilityAddTraits(item.isSelected ? .isSelected : [])
  }

  private var cardBackground: Color {
    if item.isSelected {
      return Color(nsColor: .controlBackgroundColor).opacity(0.96)
    }
    return Color(nsColor: .controlBackgroundColor).opacity(isHovering ? 0.88 : 0.74)
  }

  private var sourceAppBand: some View {
    ZStack(alignment: .trailing) {
      LinearGradient(
        colors: [
          Color(nsColor: appBandAccentColor).opacity(item.isSelected ? 0.38 : 0.28),
          Color(nsColor: appBandAccentColor).opacity(item.isSelected ? 0.23 : 0.15)
        ],
        startPoint: .leading,
        endPoint: .trailing
      )

      AppImageView(appImage: item.applicationImage, size: NSSize(width: 50, height: 50))
        .opacity(0.08)
        .blur(radius: 1.5)
        .offset(x: 9, y: 5)
        .accessibilityHidden(true)

      HStack(spacing: 9) {
        AppImageView(appImage: item.applicationImage, size: NSSize(width: 28, height: 28))
          .shadow(color: .black.opacity(0.12), radius: 2, y: 1)

        Text(item.application ?? "Clipboard")
          .font(.caption.weight(.medium))
          .foregroundStyle(.secondary)
          .lineLimit(1)

        Spacer(minLength: 4)

        if let shortcut = item.shortcuts.first, !shortcut.description.isEmpty {
          Text(shortcut.description)
            .font(.caption2.monospaced().weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 5))
        }
      }
      .padding(.horizontal, 11)
    }
    .frame(height: 50)
    .overlay(alignment: .top) {
      Rectangle()
        .fill(Color.primary.opacity(0.07))
        .frame(height: 1)
    }
    .clipped()
  }

  @ViewBuilder
  private var cardContent: some View {
    switch kind {
    case .image:
      ZStack {
        Color.primary.opacity(0.035)
        if let image = item.cardImage {
          Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .padding(4)
        } else {
          ProgressView()
            .controlSize(.small)
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

    case .file:
      let urls = item.fileURLs
      HStack(spacing: 11) {
        if let url = urls.first {
          Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 42, height: 42)
        }
        VStack(alignment: .leading, spacing: 4) {
          Text(urls.first?.lastPathComponent ?? item.title)
            .font(.body.weight(.medium))
            .lineLimit(3)
          if urls.count > 1 {
            Text("\(urls.count) files")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
      .frame(maxHeight: .infinity, alignment: .center)

    case .link:
      let value = item.previewText.trimmingCharacters(in: .whitespacesAndNewlines)
      let url = URL(string: value)
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 7) {
          Image(systemName: "globe")
            .foregroundStyle(.tint)
          Text(url?.host() ?? value)
            .font(.body.weight(.semibold))
            .lineLimit(1)
        }
        Text(value)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(4)
      }

    case .color:
      VStack(spacing: 7) {
        if let colorImage {
          Image(nsImage: colorImage)
            .resizable()
            .interpolation(.none)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
              RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.13), lineWidth: 1)
            }
        }
        Text(item.title.uppercased())
          .font(.caption.monospaced().weight(.semibold))
      }

    case .text:
      Text(item.previewText)
        .font(.system(size: 13.5))
        .lineSpacing(2)
        .lineLimit(7)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
  }

  private func selectCard() {
    if NSEvent.modifierFlags.contains(.command) && appState.multiSelectionEnabled {
      appState.navigator.addToSelection(item: item)
    } else {
      appState.navigator.select(item: item)
    }
  }

  private func performPrimaryAction() {
    selectCard()
    Task { @MainActor in
      appState.history.select(item, flags: [])
    }
  }
}
