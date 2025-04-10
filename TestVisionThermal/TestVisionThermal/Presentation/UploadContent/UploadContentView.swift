import AVFoundation
import SwiftUI

struct UploadContentView: View {
    @StateObject var viewModel: UploadContentViewModel

    var body: some View {
        ZStack {
            Color.black090909.ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                navigationBar
                
                mediaContent
                
                Spacer()
                
                FilterList
                
                mainButton
            }
        }
        .edgesIgnoringSafeArea(.top)
        .simultaneousGesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 100, abs(value.translation.width) < 50 {
                        viewModel.tapOnBackButton()
                    }
                }
        )
    }
    
    private var navigationBar: some View {
        VStack(spacing: 0) {
            Spacer()
                
            HStack(spacing: 0) {
                CircleButton(icon: .backIcon) { viewModel.tapOnBackButton() }
                    
                Spacer()
                    
                Text(viewModel.contentName.prefix(14))
                    .font(Fonts.SFProDisplay.semibold.swiftUIFont(size: 17))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 16)
                    
                Spacer()
                    
                CircleButton(icon: .backIcon) { viewModel.tapOnBackButton() }
                    .opacity(0)
                    .disabled(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
        .padding(.bottom, 8)
        .frame(height: 106)
        .zIndex(2)
    }
    
    private var mediaContent: some View {
        ZStack {
            Image(uiImage: viewModel.photo)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 343, height: 530)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundStyle(.gray2D2D2D)
                )
                .padding(.horizontal, 16)
                .padding(.top, 4)
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
        }
    }
    
    private var FilterList: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CameraFilterType.allCases, id: \.self) { type in
                        FilterTypeButton(title: type.title, isSelected: viewModel.selectedFilter == type) {
                            withAnimation {
                                viewModel.tapOnFilterButton(filterType: type)
                            }
                        }
                        .id(type)
                    }
                }
                .padding(.horizontal, 28)
            }
            .padding(.bottom, 15)
            .padding(.top, 4)
            .onChange(of: viewModel.selectedFilter) { newFilter in
                withAnimation {
                    proxy.scrollTo(newFilter, anchor: .center)
                }
            }
        }
    }
    
    private var mainButton: some View {
        MainButton(title: Strings.continueButtonTitle) {
            viewModel.tapOnContinueButton()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }
}
