import SwiftUI

struct AddSectionRow: View {
    @Binding var name: String
    let create: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.square")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 20)

            TextField("Add section", text: $name)
                .textFieldStyle(.plain)
                .foregroundStyle(AppTheme.primary)
                .onSubmit(create)

            Button("Add Section", systemImage: "plus", action: create)
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.secondary)
                .help("Add Section")
        }
        .frame(height: 30)
    }
}
