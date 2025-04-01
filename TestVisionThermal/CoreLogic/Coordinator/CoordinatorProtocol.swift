import UIKit

protocol CoordinatorProtocol: AnyObject {
    var parentCoordinator: CoordinatorProtocol? { get set }
    var childrenCoordinator: [CoordinatorProtocol] { get set }
    var navigationController: UINavigationController { get set }
    var window: UIWindow? { get set }

    func start()
}

extension CoordinatorProtocol {
    func removeChildCoordinator(_ child: CoordinatorProtocol) {
        var newChildren = [CoordinatorProtocol]()
        for coordinator in childrenCoordinator {
            if coordinator !== child {
                newChildren.append(coordinator)
            }
        }
        childrenCoordinator = newChildren
    }
}
