import SwiftUI

struct HistoryCell: View {
    let contentThumbnail: UIImage
    let contentName: String
    let contentURL: URL
    var width: CGFloat?
    let cellAction: () -> Void
    let deleteAction: () -> Void

    var body: some View {
        ZStack(alignment: .trailing) {
            Button(action: cellAction) {
                HStack(spacing: 8) {
                    Image(uiImage: contentThumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text(contentName)
                        .font(Fonts.SFProDisplay.regular.swiftUIFont(size: 15))
                        .foregroundStyle(.white)
                    
                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.leading, 16)
                .frame(width: width, height: 72)
                .frame(maxWidth: width ?? .infinity)
                .background(cellBackground)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .clipped()
            }
            
            Menu {
                ShareLink(
                    item: contentURL,
                    preview: SharePreview(contentName, image: Image(uiImage: contentThumbnail))
                ) {
                    Label(Strings.shareButtonTitle, systemImage: "square.and.arrow.up")
                }
                
                Button(role: .destructive) { deleteAction() } label: {
                    Label(Strings.deleteButtonTitle, systemImage: "trash")
                }
            } label: {
                Image(.ellipsisIcon)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(16)
                    .contentShape(Rectangle())
            }
        }
    }

    private var cellBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .black090909],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            
            RoundedRectangle(cornerRadius: 28)
                .foregroundStyle(.clear)
                .overlay(alignment: .center) {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.shadow(.inner(color: .white.opacity(0.3), radius: 12)))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .grayE9EEEA.opacity(0.12), location: 0),
                                    .init(color: .gray858886.opacity(0.12), location: 0.54),
                                    .init(color: .grayE9EEEA.opacity(0.12), location: 1.0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .blur(radius: 1)
                }
        }
    }
}
