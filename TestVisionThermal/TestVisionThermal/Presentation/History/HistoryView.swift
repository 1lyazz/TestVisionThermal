import SwiftUI

struct HistoryView: View {
    @StateObject var viewModel: HistoryViewModel

    var body: some View {
        ZStack {
            Color.black090909.ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                Spacer()
                
                Text("HistoryView")
                    .foregroundStyle(.white)
                
                Spacer()
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var header: some View {
        ZStack {
            if !viewModel.isSheetPresentation {
                MainHeader(title: Strings.historyTitle) {
                    viewModel.tapOnProButton()
                }
                .padding(.top, 15)
            } else {
                VStack(spacing: 0) {
                    Spacer()
                        
                    HStack(spacing: 0) {
                        CircleButton(icon: .closeIcon) { viewModel.tapOnCloseButton() }
                            
                        Spacer()
                            
                        Text(Strings.historyTitle)
                            .font(Fonts.SFProDisplay.semibold.swiftUIFont(size: 17))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .padding(.horizontal, 16)
                            
                        Spacer()
                            
                        CircleButton(icon: .closeIcon) { viewModel.tapOnCloseButton() }
                            .opacity(0)
                            .disabled(true)
                    }
                }
                .padding(.top, 44)
                .padding(.bottom, 12)
                .frame(height: 44)
            }
        }
    }
}
