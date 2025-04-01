import SwiftUI

struct CircleButton: View {
    let icon: ImageResource
    var size: CGFloat?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .stroke(.tertiary99889C, lineWidth: 1)
                .background(Circle().fill(.clear))
                .frame(width: size ?? 40, height: size ?? 40)
                .overlay {
                    Image(icon)
                        .resizable()
                        .scaleEffect(0.5)
                }
        }
    }
}
