import PhotosUI
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

                PhotosPicker(selection: $viewModel.selectedItem, matching: .images) {
                    Text("pushUploadContentView")
                }
                .onChange(of: viewModel.selectedItem) { newItem in
                    viewModel.selectItem(item: newItem)
                }

                Button(action: viewModel.tapOnAllHistoryButton) {
                    Text("presentHistoryView")
                }
            }
        }
    }
}
