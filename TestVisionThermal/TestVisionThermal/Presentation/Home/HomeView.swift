import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    var body: some View {
        ZStack {
            Color.black090909.ignoresSafeArea()

            VStack(spacing: 24) {
                Button(action: viewModel.tapOnCameraButton) {
                    Text("pushCameraView")
                }

                Button(action: viewModel.tapOnPhotosButton) {
                    Text("pushUploadContentView")
                }

                Button(action: viewModel.tapOnAllHistoryButton) {
                    Text("presentHistoryView")
                }
            }
        }
    }
}
