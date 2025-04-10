import UIKit

struct MediaItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let thumbnail: UIImage
    let name: String
    let creationDate: Date
}
