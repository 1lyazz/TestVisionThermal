import SwiftUI

final class Coordinator: CoordinatorProtocol {
    @Published var selectionTabBar: Int = 0
    
    var parentCoordinator: CoordinatorProtocol?
    var childrenCoordinator: [CoordinatorProtocol] = []
    var navigationController: UINavigationController
    var window: UIWindow?

    init(window: UIWindow, navigationController: UINavigationController = UINavigationController()) {
        self.window = window
        self.navigationController = navigationController
        self.navigationController.setNavigationBarHidden(true, animated: false)
    }

    func start() {
        let startAppCoordinator = StartAppCoordinator(
            window: window,
            parentCoordinator: self,
            navigationController: navigationController
        )
        childrenCoordinator.append(startAppCoordinator)
        startAppCoordinator.start()
    }
    
    func popView() {
        navigationController.popViewController(animated: true)
    }
    
    func popToRootView() {
        navigationController.popToRootViewController(animated: true)
    }
    
    func dismissView() {
        navigationController.dismiss(animated: true)
    }
    
    func showTabBar(page: Int) {
        withAnimation {
            selectionTabBar = page
        }
    }
    
    func pushCameraView() {
        pushHostingController(rootView: VisionCameraView(viewModel: .init(coordinator: self)))
    }
    
    func pushResultView(
        photo: UIImage? = nil,
        video: URL? = nil,
        photoURL: URL? = nil,
        contentName: String,
        fromThumbnail: Bool = false,
        fromUpload: Bool = false
    ) {
        let viewModel = CameraResultViewModel(
            coordinator: self,
            photo: photo,
            videoURL: video,
            photoURL: photoURL,
            contentName: contentName,
            fromThumbnail: fromThumbnail,
            fromUpload: fromUpload
        )
        pushHostingController(rootView: CameraResultView(viewModel: viewModel))
    }
    
    func pushUploadContentView(
        contentName: String,
        photo: UIImage,
        photoURL: URL? = nil,
        isEdit: Bool = false
    ) {
        let viewModel = UploadContentViewModel(
            coordinator: self,
            contentName: contentName,
            photo: photo,
            photoURL: photoURL,
            isEdit: isEdit
        )
        pushHostingController(rootView: UploadContentView(viewModel: viewModel))
    }
    
    func presentHistoryView(isSheetPresentation: Bool = false) {
        let historyView = HistoryView(viewModel: .init(coordinator: self, isSheetPresentation: isSheetPresentation))
        let hostingController = UIHostingController(rootView: historyView)
        hostingController.sheetPresentationController?.preferredCornerRadius = 28
        
        navigationController.present(hostingController, animated: true)
    }
    
    func presentTabBar() {
        let tabBarView = TabBarView(viewModel: .init(coordinator: self))
        navigationController.setViewControllers([UIHostingController(rootView: tabBarView.navigationBarHidden(true))],
                                                animated: true)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
    
    private func pushHostingController<Content: View>(rootView: Content) {
        let hostingController = UIHostingController(rootView: rootView)
        navigationController.pushViewController(hostingController, animated: true)
    }
}
