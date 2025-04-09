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

                historyListHeader

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
        .padding(.bottom, 38)
    }

    private var historyListHeader: some View {
        HStack(spacing: 0) {
            Text(Strings.historyTitle)
                .font(Fonts.SFProDisplay.bold.swiftUIFont(size: 22))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            Button(action: viewModel.tapOnAllHistoryButton) {
                Text(Strings.viewAllButtonTitle)
                    .font(Fonts.SFProDisplay.regular.swiftUIFont(size: 15))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.leading, 2)
            }
        }
        .padding(.bottom, 12)
    }
}
