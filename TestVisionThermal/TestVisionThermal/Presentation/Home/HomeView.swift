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
                .padding(.bottom, 16)

                homePanels

                Spacer()

                Button(action: viewModel.tapOnAllHistoryButton) {
                    Text("presentHistoryView")
                }

                Spacer()
            }
            .padding(.horizontal, 16)
        }
    }

    private var homePanels: some View {
        HStack(spacing: 8) {
            HomePanel(
                icon: .cameraIcon,
                title: Strings.cameraTitle,
                subTitle: Strings.takePhotoVideoTitle
            ) {
                viewModel.tapOnCameraButton()
            }

            PhotosPicker(selection: $viewModel.selectedItem, matching: .images) {
                HomePanel(
                    icon: .photosIcon,
                    title: Strings.photosTitle,
                    subTitle: Strings.importFromPhotoTitle
                )
            }
            .onChange(of: viewModel.selectedItem) { newItem in
                viewModel.selectItem(item: newItem)
            }
        }
    }
}
