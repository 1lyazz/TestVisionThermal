import SwiftUI

struct MainHeader: View {
    let title: String
    var subTitle: String?
    let action: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Fonts.SFProDisplay.bold.swiftUIFont(size: subTitle != nil ? 22 : 28))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if let subTitle {
                    Text(subTitle)
                        .font(Fonts.SFProDisplay.regular.swiftUIFont(size: 13))
                        .foregroundStyle(.gray9A9A9A)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button(action: action) {
                HStack(spacing: 4) {
                    Image(.proIcon)
                        .resizable()
                        .frame(width: 16, height: 14.22)

                    Text(Strings.proButtonTitle)
                        .font(Fonts.SFProDisplay.semibold.swiftUIFont(size: 14))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 7.5)
                .background(proButtonBackground)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .clipped()
            }
            .padding(.bottom, subTitle != nil ? 10 : 0)
        }
    }

    private var proButtonBackground: some View {
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
