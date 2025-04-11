import StoreKit
import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @Environment(\.requestReview) private var requestReview

    var body: some View {
        ZStack {
            Color.black090909.ignoresSafeArea()
            
            VStack(spacing: 0) {
                MainHeader(title: Strings.settingsTitle) {
                    viewModel.tapOnProButton()
                }
                .padding(.top, 15)
                .padding(.bottom, 33)
                
                proBanner
                
                settingsList
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5)) {
                    viewModel.isListVisible = true
                }
            }
        }
    }
    
    private var proBanner: some View {
        Image(.proBanner)
            .resizable()
            .scaledToFit()
            .overlay {
                VStack(spacing: 0) {
                    Text(Strings.proBannerTitle)
                        .font(Fonts.SFProDisplay.bold.swiftUIFont(size: 22))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
            
                    Text(Strings.proBannerMessage)
                        .font(Fonts.SFProDisplay.regular.swiftUIFont(size: 15))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                        .minimumScaleFactor(0.8)
                        .padding(.top, 4)
            
                    MainButton(
                        title: Strings.proBannerButtonTitle,
                        titleColor: .primaryB827CE,
                        icon: .diamondIcon,
                        buttonColor: .white
                    ) {
                        viewModel.tapOnProButton()
                    }
                    .padding(.top, 14)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
            }
            .padding(.bottom, 16)
    }
    
    private var settingsList: some View {
        VStack(spacing: 0) {
            ForEach(SettingsType.allCases, id: \.self) { type in
                Group {
                    switch type {
                    case .share:
                        if let appStoreURL = URL(string: AppConstants.getValue().appStoreURL) {
                            ShareLink(item: appStoreURL) { cellContent(for: type) }
                        }
                    case .rate:
                        Button {
                            requestReview()
                        } label: {
                            cellContent(for: type)
                        }
                    case .privacy:
                        if let privacyURL = URL(string: AppConstants.getValue().privacyURL) {
                            Link(destination: privacyURL) { cellContent(for: type) }
                        }
                    case .terms:
                        if let termsURL = URL(string: AppConstants.getValue().termsURL) {
                            Link(destination: termsURL) { cellContent(for: type) }
                        }
                    default:
                        Button {
                            viewModel.tapOnSettingsButton(type: type)
                        } label: {
                            cellContent(for: type)
                        }
                    }
                }
                .opacity(viewModel.isListVisible ? 1 : 0)
                .offset(y: viewModel.isListVisible ? 0 : 20)
                .animation(.easeInOut(duration: 0.3), value: viewModel.isListVisible)
            }
        }
        .padding(.vertical, 4)
        .background(listBackground)
    }
    
    private func cellContent(for type: SettingsType) -> some View {
        HStack(spacing: 0) {
            Image(type.icon)
                .resizable()
                .frame(width: 24, height: 24)
                .padding(.trailing, 10)
            
            Text(type.title)
                .font(Fonts.SFProDisplay.regular.swiftUIFont(size: 17))
                .foregroundColor(.white)
            
            Spacer()
            
            Image(.rightArrowIcon)
                .resizable()
                .frame(width: 24, height: 24)
        }
        .padding(.trailing, 10)
        .padding(.leading, 16)
        .padding(.vertical, 12)
    }
    
    private var listBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(.shadow(.inner(color: .white.opacity(0.3), radius: 12)))
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
    }
}

enum SettingsType: String, CaseIterable {
    case contact
    case share
    case restore
    case rate
    case privacy
    case terms
    
    var title: String {
        switch self {
        case .contact: Strings.contactSettings
        case .share: Strings.shareSettings
        case .restore: Strings.restoreSettings
        case .rate: Strings.rateSettings
        case .privacy: Strings.privacySettings
        case .terms: Strings.termsSettings
        }
    }
    
    var icon: ImageResource {
        switch self {
        case .contact: .contactIcon
        case .share: .shareAppIcon
        case .restore: .restoreIcon
        case .rate: .rateIcon
        case .privacy: .privacyIcon
        case .terms: .termsIcon
        }
    }
}
