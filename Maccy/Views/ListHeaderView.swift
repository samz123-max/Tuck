import Defaults
import KeyboardShortcuts
import SwiftUI

struct ListHeaderView: View {
  @FocusState.Binding var searchFocused: Bool
  @Binding var searchQuery: String

  @Environment(AppState.self) private var appState
  @Environment(\.scenePhase) private var scenePhase

  var body: some View {
    HStack {
      SearchFieldView(placeholder: "search_placeholder", query: $searchQuery)
        .focused($searchFocused)
        .overlay {
          RoundedRectangle(cornerRadius: Popup.cornerRadius)
            .strokeBorder(searchFocused ? Color.accentColor.opacity(0.55) : .clear, lineWidth: 1.5)
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .onChange(of: scenePhase) {
          if scenePhase == .background && !searchQuery.isEmpty {
            searchQuery = ""
          }
        }
        // Only reliable way to disable the cursor. allowsHitTesting() does not work
        .offset(y: appState.searchVisible ? 0 : -Popup.itemHeight)
    }
  }
}
