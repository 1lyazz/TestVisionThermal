import SwiftUI

struct SplashScreenView: View {
    @StateObject var viewModel: SplashScreenViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TimelineView(.animation(minimumInterval: 0.6, paused: false)) { timeline in
                ZStack {
                    Image(.cameraIcon)
                        .resizable()
                        .frame(width: 150, height: 150)
                        .scaleEffect(viewModel.isSplashAnimation ? 1.1 : 1)
                }
                .onChange(of: timeline.date) { _ in
                    withAnimation(.bouncy(duration: 0.8)) {
                        viewModel.isSplashAnimation.toggle()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.setupAppNavigation()
            }
        }
    }
}
