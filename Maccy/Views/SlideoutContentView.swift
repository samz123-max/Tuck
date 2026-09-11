import SwiftUI

struct SlideoutContentView: View {
  @Environment(AppState.self) var appState

  var body: some View {
    VStack {
      ToolbarView()

      if let item = appState.navigator.leadHistoryItem {
        PreviewItemView(item: item)
      } else if let pasteStack = appState.history.pasteStack,
        appState.navigator.pasteStackSelected {
        PasteStackPreviewView(pasteStack: pasteStack)
      } else {
        EmptyView()
      }
    }
    .padding(.horizontal, 18)
    .padding(.top, 16)
    .padding(.bottom, 18)
  }

}
