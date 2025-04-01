import SwiftUI

struct CameraSegmentButton: View {
    let icon: ImageResource
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(icon)
                .foregroundColor(.white)
        }
    }
}
