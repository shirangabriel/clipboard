import SwiftUI

struct SectionBlock<Content: View, TrailingMenu: View>: View {
    let title: String
    let collapsed: Bool
    let onToggle: (() -> Void)?
    @ViewBuilder let trailingMenu: TrailingMenu
    @ViewBuilder let content: Content

    init(
        title: String,
        collapsed: Bool,
        onToggle: (() -> Void)?,
        @ViewBuilder trailingMenu: () -> TrailingMenu = { EmptyView() },
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.collapsed = collapsed
        self.onToggle = onToggle
        self.trailingMenu = trailingMenu()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let onToggle {
                    Button(action: onToggle) {
                        headerContent
                    }
                    .buttonStyle(.plain)
                } else {
                    headerContent
                        .accessibilityAddTraits(.isHeader)
                }

                trailingMenu
            }

            if !collapsed {
                VStack(alignment: .leading, spacing: 6) {
                    content
                }
            }
        }
    }

    private var headerContent: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.secondary)
                .lineLimit(1)

            if onToggle != nil {
                Image(systemName: collapsed ? "chevron.right" : "chevron.down")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(AppTheme.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
