import SwiftUI

struct CameraView: View {
    @StateObject var viewModel: CameraViewModel

    var body: some View {
        ZStack {
            Color.black090909.ignoresSafeArea()

            Text("CameraView")
                .foregroundStyle(.white)
        }
    }
}
