import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel

    var body: some View {
        ZStack {
            Color.black090909.ignoresSafeArea()
            
            VStack(spacing: 0) {
                MainHeader(title: Strings.settingsTitle) {
                    viewModel.tapOnProButton()
                }
                .padding(.top, 15)
                
                Spacer()
                
                Text("SettingsView")
                    .foregroundStyle(.white)
                
                Spacer()
            }
            .padding(.horizontal, 16)
        }
    }
}
