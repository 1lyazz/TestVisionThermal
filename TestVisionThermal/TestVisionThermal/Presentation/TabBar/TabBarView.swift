import SwiftUI

struct TabBarView: View {
    @ObservedObject var viewModel: TabBarViewModel

    init(viewModel: TabBarViewModel) {
        self.viewModel = viewModel
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $viewModel.selectedIndex) {
                HomeView(viewModel: .init(coordinator: viewModel.coordinator))
                    .tag(0)

                HistoryView(viewModel: .init(coordinator: viewModel.coordinator))
                    .tag(1)

                SettingsView(viewModel: .init(coordinator: viewModel.coordinator))
                    .tag(2)
            }

            HStack(alignment: .center, spacing: 0) {
                tabBarButton
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(tabBarBackground)
            .padding(.bottom, ScreenSizer.shared.isSmallScreenHeight() ? 16 : 5)
        }
        .animation(.default, value: viewModel.selectedIndex)
        .background(.clear)
    }

    private var tabBarButton: some View {
        ForEach(TabBarItems.allCases, id: \.self) { item in
            Button(action: {
                viewModel.selectedIndex = item.rawValue
            }, label: {
                VStack(alignment: .center, spacing: 4) {
                    Image(item.icon)
                        .renderingMode(.template)
                        .foregroundStyle(item.rawValue == viewModel.selectedIndex ? .white : .gray8C8C8C)

                    Text(item.title)
                        .font(Fonts.SFProDisplay.medium.swiftUIFont(size: 12))
                        .foregroundStyle(item.rawValue == viewModel.selectedIndex ? .white : .gray8C8C8C)
                }
            })
            .frame(width: 90)
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var tabBarBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .black090909],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )

            RoundedRectangle(cornerRadius: 40)
                .foregroundStyle(.clear)
                .overlay(alignment: .center) {
                    RoundedRectangle(cornerRadius: 40)
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

#Preview {
    TabBarView(viewModel: .init(coordinator: .init(window: UIWindow())))
}
