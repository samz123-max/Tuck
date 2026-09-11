import SwiftUI

struct SearchFieldView: View {
  var placeholder: LocalizedStringKey
  @Binding var query: String

  @Environment(AppState.self) private var appState

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: Popup.cornerRadius, style: .continuous)
        .fill(Color(nsColor: .textBackgroundColor).opacity(0.72))
        .overlay {
          RoundedRectangle(cornerRadius: Popup.cornerRadius)
            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
        }
        .frame(height: 38)

      HStack {
        Image(systemName: "magnifyingglass")
          .frame(width: 11, height: 11)
          .padding(.leading, 12)
          .foregroundStyle(.secondary)
          .accessibilityHidden(true)

        TextField(placeholder, text: $query)
          .disableAutocorrection(true)
          .lineLimit(1)
          .textFieldStyle(.plain)
          .font(.system(size: 13.5))
          .accessibilityLabel("Search clipboard history")
          .onSubmit {
            appState.select(flags: .currentModifierFlags)
          }

        if !query.isEmpty {
          Button {
            query = ""
          } label: {
            Image(systemName: "xmark.circle.fill")
              .frame(width: 11, height: 11)
              .padding(.trailing, 11)
          }
          .buttonStyle(.plain)
          .opacity(0.9)
          .accessibilityLabel(Text("search_clear_accessibility_label"))
        }
      }
    }
  }
}

#Preview {
  return List {
    SearchFieldView(placeholder: "search_placeholder", query: .constant(""))
    SearchFieldView(placeholder: "search_placeholder", query: .constant("search"))
  }
  .frame(width: 300)
  .environment(\.locale, .init(identifier: "en"))
}
