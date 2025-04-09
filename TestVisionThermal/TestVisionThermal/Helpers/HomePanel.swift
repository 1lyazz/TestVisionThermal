import SwiftUI

struct HomePanel: View {
    let icon: ImageResource
    let title: String
    var subTitle: String
    var action: (() -> Void)?

    var body: some View {
        if let action = action {
            Button(action: action) {
                panelContent
            }
        } else {
            panelContent
        }
    }

    private var panelContent: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Image(icon)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .padding(.bottom, 8)

                Text(title)
                    .font(Fonts.SFProDisplay.semibold.swiftUIFont(size: 17))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.bottom, 3)

                Text(subTitle)
                    .font(Fonts.SFProDisplay.regular.swiftUIFont(size: 13))
                    .foregroundStyle(.gray9A9A9A)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.leading, 12)
        .frame(width: 167.5)
        .background(tabBarBackground)
    }

    private var tabBarBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .black090909],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )

            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.clear)
                .overlay(alignment: .center) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.shadow(.inner(color: .white.opacity(0.3), radius: 12)))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .grayE9EEEA.opacity(0.12), location: 0),
                                    .init(color: .gray858886.opacity(0.12), location: 0.54),
                                    .init(color: .grayE9EEEA.opacity(0.12), location: 1.0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .blur(radius: 1)
                }
        }
    }
}
