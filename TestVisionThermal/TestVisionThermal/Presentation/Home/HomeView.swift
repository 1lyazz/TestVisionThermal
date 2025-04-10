import AlertToast
import PhotosUI
import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    var body: some View {
        ZStack {
            Color.black090909
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, 16)

                contentSection

                Spacer()
            }
        }
        .onAppear {
            viewModel.isLoading = true
            viewModel.loadMediaFiles()
        }
    }
}

// MARK: - Header Section

extension HomeView {
    private var headerSection: some View {
        VStack(spacing: 0) {
            MainHeader(
                title: UIApplication.shared.appName,
                subTitle: Strings.tapOnTransformTitle
            ) {
                viewModel.tapOnProButton()
            }
            .padding(.top, 14)
            .padding(.bottom, 16)

            homePanels

            historyListHeader
                .padding(.bottom, 17)
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
    }
}

// MARK: - Content Section

extension HomeView {
    private var contentSection: some View {
        Group {
            if viewModel.isLoading {
                AlertToast(
                    displayMode: .alert,
                    type: .loading,
                    style: .style(backgroundColor: .clear)
                )
                .frame(height: 231)
            } else {
                if !viewModel.mediaItems.isEmpty {
                    historyList
                } else {
                    emptyView
                }
            }
        }
    }

    private var historyList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 8) {
                ForEach(viewModel.mediaItems.chunked(into: 3), id: \.self) { column in
                    VStack(spacing: 8) {
                        ForEach(column, id: \.id) { item in
                            HistoryCell(
                                contentThumbnail: item.thumbnail,
                                contentName: item.name,
                                contentURL: item.url,
                                width: 270,
                                cellAction: { viewModel.tapOnHistoryCell(with: item) },
                                deleteAction: { viewModel.tapOnDelete(item) }
                            )
                        }
                    }
                }
            }
            .padding(.leading, 16)
        }
        .scrollIndicators(.hidden)
    }

    private var emptyView: some View {
        VStack(spacing: 4) {
            Image(.folderIcon)
                .resizable()
                .frame(width: 80, height: 80)

            Text(Strings.noPhotosTitle)
                .font(Fonts.SFProDisplay.bold.swiftUIFont(size: 22))
                .foregroundStyle(.white)
                .lineLimit(1)
                .multilineTextAlignment(.center)

            Text(Strings.historyWillAppearTitle)
                .font(Fonts.SFProDisplay.regular.swiftUIFont(size: 13))
                .foregroundStyle(.gray9A9A9A)
                .lineLimit(1)
                .multilineTextAlignment(.center)
        }
        .frame(height: 231)
    }
}
