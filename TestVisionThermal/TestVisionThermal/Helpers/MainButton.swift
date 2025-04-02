import SwiftUI

struct MainButton: View {
    let title: String
    var icon: ImageResource?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(icon)
                        .resizable()
                        .frame(width: 20, height: 20)
                }

                Text(title)
                    .font(Fonts.SFProDisplay.semibold.swiftUIFont(size: 17))
                    .foregroundStyle(.white)
            }
            .frame(height: 54)
            .frame(maxWidth: .infinity)
            .background(mainButtonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .clipped()
        }
    }

    private var mainButtonBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .foregroundStyle(.primaryB827CE)

            RoundedRectangle(cornerRadius: 40)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.7), .purple540560],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 5
                )
                .blur(radius: 6)
        }
    }
}
