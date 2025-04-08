import AlertToast
import AVFoundation
import sharelink_for_swiftui
import SwiftUI

struct CameraResultView: View {
    @StateObject var viewModel: CameraResultViewModel
    
    var body: some View {
        ZStack {
            Color.black090909
            
            VStack(spacing: 0) {
                navigationBar
                
                mediaContent
                
                Spacer()
                
                saveButton
            }
        }
        .edgesIgnoringSafeArea(.top)
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
                    
                shareButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
        .padding(.bottom, 8)
        .frame(height: 106)
    }
    
    private var mediaContent: some View {
        Group {
            if let photo = viewModel.photo {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 351, height: 543)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else if let videoURL = viewModel.videoURL {
                VideoPlayerView(videoURL: videoURL, autoPlay: true)
                    .frame(width: 351, height: 543)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .onDisappear {
                        AVPlayer(url: videoURL).pause()
                    }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.gray2D2D2D)
        )
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }
    
    private var saveButton: some View {
        MainButton(title: Strings.saveToGalleryButtonTitle, icon: .saveIcon) {
            viewModel.tapOnSaveButton()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 13)
    }
    
    private var shareButton: some View {
        Group {
            if let photo = viewModel.photo {
                ShareLinkButton(item: photo, title: String(viewModel.contentName.prefix(14))) {
                    Circle()
                        .stroke(.tertiary99889C, lineWidth: 1)
                        .background(Circle().fill(.clear))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(.shareIcon)
                                .resizable()
                                .scaleEffect(0.5)
                        }
                }
            } else if let videoURL = viewModel.videoURL {
                ShareLink(
                    item: videoURL,
                    preview: SharePreview(viewModel.contentName.prefix(14), image: Image(uiImage: viewModel.videoThumbnail ?? .cameraIcon)),
                    label: {
                        Circle()
                            .stroke(.tertiary99889C, lineWidth: 1)
                            .background(Circle().fill(.clear))
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(.shareIcon)
                                    .resizable()
                                    .scaleEffect(0.5)
                            }
                    }
                )
            }
        }
    }
}
