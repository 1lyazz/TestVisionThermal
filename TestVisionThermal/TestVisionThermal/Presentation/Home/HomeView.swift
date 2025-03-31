import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    var body: some View {
        ZStack {
            Color.black090909.ignoresSafeArea()

            VStack {
                Button(action: viewModel.coordinator.pushCameraView) {
                    Text("pushCameraView")
                }

                Button(action: viewModel.coordinator.presentHistoryView) {
                    Text("presentHistoryView")
                }
            }
        }
    }
}
