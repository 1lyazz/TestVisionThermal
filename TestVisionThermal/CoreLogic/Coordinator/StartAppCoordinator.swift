import SwiftUI

final class StartAppCoordinator: CoordinatorProtocol {
    var parentCoordinator: CoordinatorProtocol?
    var childrenCoordinator: [CoordinatorProtocol] = []
    var navigationController: UINavigationController
    var window: UIWindow?
    
    init(window: UIWindow?, parentCoordinator: CoordinatorProtocol, navigationController: UINavigationController) {
        self.window = window
        self.parentCoordinator = parentCoordinator
        self.navigationController = navigationController
    }
    
    func start() {
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        let splashScreen = SplashScreenView(viewModel: .init(coordinator: self))
        navigationController.setViewControllers([UIHostingController(rootView: splashScreen.navigationBarHidden(true))], animated: true)
    }
    
    func handleSplashCompletion() async {
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
//                group.addTask { try await ConfigManager.shared.fetchAppConfigs() }
//                group.addTask { try await Task.sleep(nanoseconds: 5_000_000_000) }
                
                try await group.next()
                group.cancelAll()
            }
        } catch {
            print("Config fetch failed: \(error)")
        }
        
        await MainActor.run {
//            if UserDefaults.standard.bool(forKey: AppConstants.onboardingDone) {
            (parentCoordinator as? Coordinator)?.presentTabBar()
//            } else {
//                (parentCoordinator as? Coordinator)?.presentOnboardingView()
//            }
            
            parentCoordinator?.removeChildCoordinator(self)
        }
    }
}
