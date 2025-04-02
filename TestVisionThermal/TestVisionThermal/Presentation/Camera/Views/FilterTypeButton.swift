import SwiftUI

struct FilterTypeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Fonts.SFProDisplay.regular.swiftUIFont(size: 15))
                .foregroundStyle(.white)
                .padding(.vertical, 13)
                .padding(.horizontal, 24)
                .background(buttonBackground)
        }
        .frame(height: 44)
    }

    private var buttonBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(.shadow(.inner(color: isSelected ? .white.opacity(0.44) : .clear, radius: 6)))
                .foregroundStyle(isSelected ? .black090909 : .clear)

            RoundedRectangle(cornerRadius: 28)
                .stroke(isSelected ? .grayC7C7C7 : .clear, lineWidth: 0.5)
                .frame(height: 43)
        }
    }
}

#Preview {
    ZStack {
        Color.black090909.ignoresSafeArea()

        FilterTypeButton(title: "Original", isSelected: true, action: { print("") })
    }
}
