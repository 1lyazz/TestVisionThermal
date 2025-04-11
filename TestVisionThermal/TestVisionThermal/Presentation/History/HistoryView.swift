import AlertToast
import SwiftUI

struct HistoryView: View {
    @StateObject var viewModel: HistoryViewModel

    var body: some View {
        ZStack {
            Color.black090909.ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                filterList
                
                contentSection
                    .animation(.default, value: viewModel.isLoading)
                    .transition(.opacity)
            }
            
            if viewModel.isLoading {
                AlertToast(
                    displayMode: .alert,
                    type: .loading,
                    style: .style(backgroundColor: .clear)
                )
            }
            
            if viewModel.filteredMediaItems.isEmpty && !viewModel.isLoading {
                emptyView
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .transition(.opacity)
            }
        }
        .onAppear {
            viewModel.isLoading = true
            viewModel.loadMediaFiles()
        }
    }
    
    private var header: some View {
        ZStack {
            if !viewModel.isSheetPresentation {
                MainHeader(title: Strings.historyTitle) {
                    viewModel.tapOnProButton()
                }
                .padding(.top, 15)
                .padding(.bottom, 25)
            } else {
                VStack(spacing: 0) {
                    Spacer()
                        
                    HStack(spacing: 0) {
                        CircleButton(icon: .closeIcon) { viewModel.tapOnCloseButton() }
                            
                        Spacer()
                            
                        Text(Strings.historyTitle)
                            .font(Fonts.SFProDisplay.semibold.swiftUIFont(size: 17))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .padding(.horizontal, 16)
                            
                        Spacer()
                            
                        CircleButton(icon: .closeIcon) { viewModel.tapOnCloseButton() }
                            .opacity(0)
                            .disabled(true)
                    }
                }
                .padding(.top, 44)
                .padding(.bottom, 12)
                .frame(height: 44)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var filterList: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    let allFilters: [HistoryFilterType] = [.all] + CameraFilterType.allCases.map { .filter($0) }

                    ForEach(allFilters, id: \.self) { type in
                        FilterTypeButton(title: type.title, isSelected: viewModel.selectedFilter == type) {
                            withAnimation {
                                viewModel.tapOnFilterButton(filterType: type)
                            }
                        }
                        .id(type)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onChange(of: viewModel.selectedFilter) { newFilter in
                withAnimation {
                    proxy.scrollTo(newFilter, anchor: .center)
                }
            }
        }
        .padding(.top, viewModel.isSheetPresentation ? 32 : 0)
    }
    
    private var contentSection: some View {
        Group {
            if !viewModel.isLoading {
                if !viewModel.mediaItems.isEmpty {
                    historyList
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .transition(.opacity)
                        .simultaneousGesture(
                            DragGesture()
                                .onEnded { value in
                                    let horizontalAmount = value.translation.width
                                    if horizontalAmount < -50 {
                                        viewModel.swipeLeftToNextFilter()
                                    } else if horizontalAmount > 50 {
                                        viewModel.swipeRightToPreviousFilter()
                                    }
                                }
                        )
                } else {
                    Spacer()
                }
            } else {
                Spacer()
            }
        }
    }
    
    private var historyList: some View {
        ZStack(alignment: .top) {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .center, spacing: 8) {
                    ForEach(viewModel.filteredMediaItems, id: \.id) { item in
                        HistoryCell(
                            contentThumbnail: item.thumbnail,
                            contentName: item.name,
                            contentURL: item.url,
                            cellAction: { viewModel.tapOnHistoryCell(with: item) },
                            deleteAction: { viewModel.tapOnDelete(item) },
                            editAction: { viewModel.tapOnEdit(item) }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 100)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.filteredMediaItems)
            }
            .padding(.horizontal, 16)
            
            Rectangle()
                .frame(height: 12)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .black090909, location: 0.1),
                            .init(color: .clear, location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
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
                .padding(.top, 2)
            
            MainButton(title: Strings.goCameraButtonTitle) {
                viewModel.tapOnCameraButton()
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, 40)
        .padding(.top, viewModel.isSheetPresentation ? 37 : 78)
    }
}
