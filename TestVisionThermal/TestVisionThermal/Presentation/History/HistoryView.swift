import SwiftUI

struct HistoryView: View {
    @StateObject var viewModel: HistoryViewModel

    var body: some View {
        ZStack {
            Color.black090909.ignoresSafeArea()
            
            Text("HistoryView")
                .foregroundStyle(.white)
        }
    }
}
