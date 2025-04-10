import AlertToast
import AVFoundation
import sharelink_for_swiftui
import SwiftUI

struct CameraResultView: View {
    @StateObject var viewModel: CameraResultViewModel
    
    var body: some View {
        ZStack {
            Color.black090909.ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                navigationBar
                
                mediaContent
                
                Spacer()
                
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
        .alert(isPresented: $viewModel.isShowAlert) {
            switch viewModel.alertType {
            case .ok:
                if viewModel.isOnSettingsButton {
                    return Alert(
                        title: Text(viewModel.alertTitle),
                        message: Text(viewModel.alertDescription),
                        primaryButton: .cancel(Text(Strings.okButtonTitle)) {
                            viewModel.isShowAlert = false
                        },
                        secondaryButton: .default(Text(Strings.settingsButtonTitle)) {
                            UIApplication.shared.openPhoneSettings()
                        }
                    )
                } else {
                    return Alert(
                        title: Text(viewModel.alertTitle),
                        message: Text(viewModel.alertDescription),
                        dismissButton: .cancel(Text(Strings.okButtonTitle)) {
                            viewModel.isShowAlert = false
                        }
                    )
                }
            case .cancel:
                return Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertDescription),
                    primaryButton: .cancel(Text(Strings.cancelButtonTitle)) {
                        viewModel.isShowAlert = false
                    },
                    secondaryButton: .destructive(Text(Strings.deleteButtonTitle)) {
                        viewModel.isShowAlert = false
                        viewModel.deleteContent()
                    }
                )
            }
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
                    
                if viewModel.fromThumbnail == false {
                    shareButton
                } else if viewModel.videoURL != nil {
                    CircleButton(icon: .binIcon) { viewModel.tapOnDeleteButton() }
                } else {
                    actionMenu
                }
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
                        .id(videoURL)
                        .onDisappear {
                            AVPlayer(url: videoURL).pause()
                        }
                }
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        guard value.startLocation.x > 40 else { return }
                    }
                    .onEnded { value in
                        guard value.startLocation.x > 40 else { return }
                        if value.translation.width < -50 {
                            withAnimation {
                                viewModel.showPreviousMedia()
                            }
                        } else if value.translation.width > 50 {
                            withAnimation {
                                viewModel.showNextMedia()
                            }
                        }
                    }
            )
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .foregroundStyle(.gray2D2D2D)
            )
            .padding(.horizontal, 12)
            .padding(.top, 4)
        }
    }

    private var mainButton: some View {
        ZStack {
            if viewModel.fromThumbnail == false {
                MainButton(title: Strings.saveToPhotosButtonTitle, icon: .saveIcon) {
                    viewModel.tapOnSaveButton()
                }
            } else {
                shareButton
                    .frame(height: 54)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .clipped()
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 13)
    }
    
    private var shareButton: some View {
        Group {
            if let photo = viewModel.photo {
                ShareLinkButton(item: photo, title: String(viewModel.contentName.prefix(14))) {
                    shareButtonLabel
                }
            } else if let videoURL = viewModel.videoURL {
                ShareLink(
                    item: videoURL,
                    preview: SharePreview(viewModel.contentName.prefix(14), image: Image(uiImage: viewModel.videoThumbnail ?? .cameraIcon)),
                    label: {
                        shareButtonLabel
                    }
                )
            }
        }
    }
    
    private var shareButtonLabel: some View {
        ZStack {
            if viewModel.fromThumbnail == false {
                Circle()
                    .stroke(.tertiary99889C, lineWidth: 1)
                    .background(Circle().fill(.clear))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(.shareIcon)
                            .resizable()
                            .scaleEffect(0.5)
                    }
            } else {
                RoundedRectangle(cornerRadius: 28)
                    .foregroundStyle(.primaryB827CE)

                RoundedRectangle(cornerRadius: 40)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.7), .purple540560],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 5
                    )
                    .blur(radius: 6)
                
                HStack(spacing: 8) {
                    Image(.shareIcon)
                        .resizable()
                        .frame(width: 20, height: 20)
                    
                    Text(Strings.shareButtonTitle)
                        .font(Fonts.SFProDisplay.semibold.swiftUIFont(size: 17))
                        .foregroundStyle(.white)
                }
            }
        }
    }
    
    private var actionMenu: some View {
        Menu {
            Button {
                viewModel.tapOnEdit(
                    contentName: viewModel.contentName,
                    photo: viewModel.photo ?? .emptyThumbnail,
                    photoURL: viewModel.photoURL
                )
            } label: {
                Label(Strings.editButtonTitle, systemImage: "pencil")
            }
            
            Button(role: .destructive) { viewModel.tapOnDeleteButton() } label: {
                Label(Strings.deleteButtonTitle, systemImage: "trash")
            }
        } label: {
            Circle()
                .stroke(.tertiary99889C, lineWidth: 1)
                .background(Circle().fill(.clear))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(.ellipsisIcon)
                        .resizable()
                        .frame(width: 20, height: 20)
                }
        }
    }
}
