enum HistoryFilterType: Hashable {
    case all
    case filter(CameraFilterType)

    var title: String {
        switch self {
        case .all:
            return Strings.allTitle
        case .filter(let type):
            return type.title
        }
    }
}
