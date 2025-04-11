import SwiftUI

struct MainButton: View {
    let title: String
    var titleColor: Color?
    var icon: ImageResource?
    var buttonColor: Color?
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
                    .foregroundStyle(titleColor ?? .white)
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
                .foregroundStyle(buttonColor ?? .primaryB827CE)

            if buttonColor == nil {
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
}
