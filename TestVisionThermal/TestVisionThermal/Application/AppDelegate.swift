import UIKit

final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return createSceneConfiguration(for: connectingSceneSession.role)
    }
    
    private func createSceneConfiguration(for role: UISceneSession.Role) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: role
        )
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
}
