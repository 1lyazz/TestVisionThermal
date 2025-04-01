import SwiftUI

struct VisionCameraView: View {
    @StateObject var viewModel: VisionCameraViewModel

    var body: some View {
        ZStack {
            Color.black090909
            
            CameraView(cameraSessionManager: viewModel.cameraSessionManager)
            
            VStack(spacing: 0) {
                cameraHeader
                
                if viewModel.selectCameraType == .videoCamera {
                    videoTimer
                }
                
                Spacer()
                
                FilterList
                
                cameraFooter
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private var cameraHeader: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(.black.opacity(0.7))
            
            VStack(spacing: 0) {
                Spacer()
                
                HStack(spacing: 0) {
                    CircleButton(icon: .backIcon) { viewModel.tapOnBackButton() }
                    
                    Spacer()
                    
                    cameraSegment
                    
                    Spacer()
                    
                    CircleButton(icon: viewModel.isFlashOn ? .flashOnIcon : .flashOffIcon) { viewModel.tapOnFlashButton() }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 2)
            }
            .padding(.bottom, 8)
        }
        .frame(height: 106)
    }
    
    private var cameraFooter: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(.black.opacity(0.7))
            
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    CircleButton(icon: .backIcon) { viewModel.tapOnBackButton() }
                    
                    Spacer()
                    
                    cameraButton
                    
                    Spacer()
                    
                    CircleButton(icon: .flipIcon, size: 44) { viewModel.tapOnFlipButton() }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 4)
                
                Spacer()
            }
            .padding(.top, 12)
        }
        .frame(height: 122)
    }
    
    private var cameraSegment: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .stroke(.tertiary99889C, lineWidth: 1)
                .background(Circle().fill(.clear))
                .frame(width: 78, height: 40)
            
            Circle()
                .fill(.shadow(.inner(color: .white.opacity(0.44), radius: 5)))
                .frame(width: 40, height: 40)
                .foregroundStyle(.primaryB827CE)
                .offset(x: viewModel.segmentOffset)
            
            HStack(spacing: 18) {
                ForEach(CameraType.allCases, id: \.self) { type in
                    CameraSegmentButton(icon: type.cameraIcon, isSelected: viewModel.selectCameraType == type) {
                        withAnimation {
                            viewModel.tapOnSegmentButton(cameraType: type)
                        }
                    }
                }
            }
        }
    }
    
    private var videoTimer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 74, height: 27)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .grayE9EEEA.opacity(0.1), location: 0),
                            .init(color: .gray959595.opacity(0.1), location: 0.26),
                            .init(color: .gray7E7E7E.opacity(0.1), location: 0.48),
                            .init(color: .gray959595.opacity(0.1), location: 0.69),
                            .init(color: .grayE9EEEA.opacity(0.1), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Text("00:00:10")
                .font(Fonts.SFProDisplay.regular.swiftUIFont(size: 13))
                .foregroundStyle(.white)
        }
        .padding(.top, 16)
    }
    
    private var FilterList: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(CameraFilterType.allCases, id: \.self) { type in
                    FilterTypeButton(title: type.title, isSelected: viewModel.selectedFilter == type) {
                        withAnimation {
                            viewModel.tapOnFilterButton(filterType: type)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
        .padding(.bottom, 16)
    }
    
    private var cameraButton: some View {
        Button(action: viewModel.tapOnCameraButton) {
            ZStack {
                Circle()
                    .stroke(.primaryB827CE, lineWidth: 3)
                    .background(Circle().fill(.clear))
                    .frame(width: 59, height: 59)
                    
                Circle()
                    .foregroundStyle(.primaryB827CE)
                    .frame(width: 48, height: 48)
            }
        }
    }
}
