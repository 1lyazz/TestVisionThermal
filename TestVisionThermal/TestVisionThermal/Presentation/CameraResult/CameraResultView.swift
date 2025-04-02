import AlertToast
import sharelink_for_swiftui
import SwiftUI

struct CameraResultView: View {
    @StateObject var viewModel: CameraResultViewModel
    
    var body: some View {
        ZStack {
            Color.black090909
            
            VStack(spacing: 0) {
                navigationBar
                
                photoView
                
                Spacer()
                
                MainButton(title: Strings.saveToGalleryButtonTitle, icon: .saveIcon) {
                    viewModel.tapOnSaveButton()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 13)
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
                title: Strings.savedPhotoTitle,
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
                    
                Text("Image1")
                    
                Spacer()
                    
                shareButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
        .padding(.bottom, 8)
        .frame(height: 106)
    }
    
    private var photoView: some View {
        Image(uiImage: viewModel.photo)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 351, height: 543)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .foregroundStyle(.gray2D2D2D)
            )
            .padding(.horizontal, 12)
            .padding(.top, 4)
    }
    
    private var shareButton: some View {
        ShareLinkButton(
            item: viewModel.photo,
            title: UIApplication.shared.appName,
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
