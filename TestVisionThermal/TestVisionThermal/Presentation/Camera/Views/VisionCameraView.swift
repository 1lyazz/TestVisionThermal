import AlertToast
import SwiftUI

struct VisionCameraView: View {
    @StateObject var viewModel: VisionCameraViewModel

    var body: some View {
        ZStack {
            Color.black090909
            
            if viewModel.isCameraAccess {
                CameraView(cameraSessionManager: viewModel.cameraSessionManager, error: $viewModel.cameraError)
                    .blur(radius: viewModel.isChangeCameraState ? 10 : 0)
                    .opacity(viewModel.isCameraVisible ? 1 : 0)
            }
            
            VStack(spacing: 0) {
                cameraHeader
                
                if viewModel.selectCameraType == .videoCamera && viewModel.isCameraAccess {
                    videoTimer
                }
                
                Spacer()
                
                if viewModel.isCameraAccess {
                    FilterList
                        .opacity(viewModel.isRecording ? 0.6 : 1)
                        .animation(.default, value: viewModel.isRecording)
                        .transition(.opacity)
                    
                    cameraFooter
                }
            }
            
            if !viewModel.isCameraAccess {
                noCameraAccessView
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            viewModel.loadLastSavedContentURL(for: viewModel.selectCameraType)
            viewModel.isDisableCameraButton = false
        }
        .onDisappear {
            viewModel.cameraSessionManager.stopSessionAndCleanup()
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.isShowAlert) {
            Button(Strings.okButtonTitle) {
                viewModel.isShowAlert = false
            }
            
            if viewModel.isOnSettingsButton {
                Button(Strings.settingsButtonTitle) {
                    UIApplication.shared.openPhoneSettings()
                }
            }
        } message: {
            Text(viewModel.alertDescription)
        }
        .toast(isPresenting: $viewModel.isShowToast) {
            AlertToast(
                displayMode: .hud,
                type: .regular,
                title: viewModel.toastTitle,
                style: .style(
                    backgroundColor: .primaryB827CE,
                    titleColor: .white
                )
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            viewModel.applicationWillResignActive()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            viewModel.applicationDidBecomeActive()
        }
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
                        .opacity(viewModel.isRecording ? 0.6 : 1)
                        .animation(.default, value: viewModel.isRecording)
                        .transition(.opacity)
                    
                    Spacer()
                    
                    CircleButton(icon: viewModel.isFlashOn ? .flashOnIcon : .flashOffIcon) { viewModel.tapOnFlashButton() }
                        .opacity(viewModel.isFrontCamera ? 0 : 1)
                        .opacity(!viewModel.isCameraAccess ? 0.6 : 1)
                        .animation(.default, value: viewModel.isFrontCamera)
                        .transition(.opacity)
                        .disabled(!viewModel.isCameraAccess)
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
                    Image(uiImage: viewModel.contentThumbnail ?? .emptyThumbnail)
                        .resizable()
                        .frame(width: 40, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .animation(.default, value: viewModel.contentThumbnail)
                        .transition(.opacity)
                        .onTapGesture {
                            viewModel.tapOnThumbnail()
                        }
                    
                    Spacer()
                    
                    cameraButton
                    
                    Spacer()
                    
                    CircleButton(icon: .flipIcon, size: 44) { viewModel.tapOnFlipButton() }
                        .opacity(viewModel.isRecording ? 0 : 1)
                        .animation(.default, value: viewModel.isRecording)
                        .transition(.opacity)
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
                            viewModel.tapOnCameraSegmentButton(cameraType: type)
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
                .foregroundStyle(viewModel.isRecording ? (viewModel.selectedFilter == .original ? .redCE272A.opacity(0.7) : .redCE272A) : .black090909.opacity(0.7))
                .animation(.default, value: viewModel.isRecording)
                .transition(.opacity)
            
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
            
            Text(viewModel.formattedRecordingTime)
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
                    
                RoundedRectangle(cornerRadius: viewModel.isRecording ? 10 : 24)
                    .foregroundStyle(.primaryB827CE)
                    .frame(
                        width: viewModel.isRecording ? 35 : 48,
                        height: viewModel.isRecording ? 35 : 48
                    )
                    .animation(.easeInOut(duration: 0.3), value: viewModel.isRecording)
            }
        }
        .disabled(viewModel.isDisableCameraButton)
    }
    
    private var noCameraAccessView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Image(.noCameraIcon)
                    
                Text(Strings.noCameraAccessTitle)
                    .font(Fonts.SFProDisplay.bold.swiftUIFont(size: 22))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    
                Text(Strings.noCameraAccessDescription)
                    .font(Fonts.SFProDisplay.regular.swiftUIFont(size: 13))
                    .foregroundColor(.gray9A9A9A)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            
            if viewModel.isOnSettingsButton {
                MainButton(title: Strings.goSettingsButtonTitle) {
                    UIApplication.shared.openPhoneSettings()
                }
            }
        }
        .padding(.horizontal, 40)
    }
}
