enum TabBarItems: Int, CaseIterable {
    case home
    case history
    case settings
    
    var title: String {
        switch self {
        case .home:
            return Strings.homeButtonTitle
        case .history:
            return Strings.historyButtonTitle
        case .settings:
            return Strings.settingsButtonTitle
        }
    }
    
    var icon: ImageResource {
        switch self {
        case .home:
            return .homeIcon
        case .history:
            return .historyIcon
        case .settings:
            return .settingsIcon
        }
    }
}
