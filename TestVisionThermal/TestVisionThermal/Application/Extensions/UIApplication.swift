import SafariServices
import StoreKit
import UIKit

extension UIApplication {
    var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Vision"
    }

    var topViewController: UIViewController? {
        var topViewController = connectedScenes.compactMap {
            ($0 as? UIWindowScene)?.windows
                .filter { $0.isKeyWindow }
                .first?
                .rootViewController
        }
        .first

        if let presented = topViewController?.presentedViewController {
            topViewController = presented
        } else if let navController = topViewController as? UINavigationController {
            topViewController = navController.topViewController
        } else if let tabBarController = topViewController as? UITabBarController {
            topViewController = tabBarController.selectedViewController
        }
        return topViewController
    }

    func openPhoneSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
}
