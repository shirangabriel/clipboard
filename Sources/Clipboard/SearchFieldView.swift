import SwiftUI

struct SearchFieldView: View {
    @Binding var searchText: String
    @FocusState.Binding var searchFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.secondary)
                .frame(width: 20)

            TextField("Search", text: $searchText)
                .textFieldStyle(.plain)
                .focused($searchFocused)
                .foregroundStyle(AppTheme.primary)
        }
        .frame(height: 30)
    }
}
