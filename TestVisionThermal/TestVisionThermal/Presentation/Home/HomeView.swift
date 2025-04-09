import PhotosUI
import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    var body: some View {
        ZStack {
            Color.black090909.ignoresSafeArea()

            VStack(spacing: 0) {
                MainHeader(title: UIApplication.shared.appName, subTitle: Strings.tapOnTransformTitle) {
                    viewModel.tapOnProButton()
                }
                .padding(.top, 14)
                
                Spacer()

                Button(action: viewModel.tapOnCameraButton) {
                    Text("pushCameraView")
                }
                .padding(.bottom, 20)

                PhotosPicker(selection: $viewModel.selectedItem, matching: .images) {
                    Text("pushUploadContentView")
                }
                .onChange(of: viewModel.selectedItem) { newItem in
                    viewModel.selectItem(item: newItem)
                }
                .padding(.bottom, 20)

                Button(action: viewModel.tapOnAllHistoryButton) {
                    Text("presentHistoryView")
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
        }
    }
}
