import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    var body: some View {
        ZStack {
            Color.black090909.ignoresSafeArea()

            VStack(spacing: 24) {
                Button(action: viewModel.coordinator.pushCameraView) {
                    Text("pushCameraView")
                }

                Button(action: { viewModel.coordinator.pushUploadContentView(contentName: "Image-123321", photo: .simulatorPhoto) }) {
                    Text("pushUploadContentView")
                }

                Button(action: viewModel.coordinator.presentHistoryView) {
                    Text("presentHistoryView")
                }
            }
        }
    }
}
