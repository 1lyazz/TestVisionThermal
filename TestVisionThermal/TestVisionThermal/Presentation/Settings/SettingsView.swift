import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel

    var body: some View {
        ZStack {
            Color.black090909.ignoresSafeArea()
            
            Text("SettingsView")
                .foregroundStyle(.white)
        }
    }
}
