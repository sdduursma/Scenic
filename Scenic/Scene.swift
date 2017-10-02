import UIKit

protocol SceneFactory {

    func makeScene(for sceneName: String) -> Scene?
}

protocol Scene {

    var viewController: UIViewController { get }

    func embed(_ children: [Scene], customData: [AnyHashable: AnyHashable]?)
}

extension Scene {

    func embed(_ children: [Scene], customData: [AnyHashable: AnyHashable]?) { }
}

protocol SceneModel {

    var sceneName: String { get set }
    var children: [SceneModel] { get set }
    var presented: SceneModel? { get set }
    var customData: [AnyHashable: AnyHashable]? { get set }
}

struct SceneModelImpl: SceneModel {

    var sceneName: String
    var children: [SceneModel]
    var presented: SceneModel?
    var customData: [AnyHashable: AnyHashable]?

    init(sceneName: String,
         children: [SceneModel] = [],
         presented: SceneModel? = nil,
         customData: [AnyHashable: AnyHashable]? = nil) {
        self.sceneName = sceneName
        self.children = children
        self.presented = presented
        self.customData = customData
    }
}

class StackScene: Scene {

    private let navigationController: UINavigationController

    var viewController: UIViewController {
        return navigationController
    }

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func embed(_ children: [Scene], customData: [AnyHashable: AnyHashable]?) {
        let childViewControllers = children.map { $0.viewController }
        navigationController.setViewControllers(childViewControllers, animated: false)
    }
}

class TabBarScene: Scene {

    private let tabBarController: UITabBarController

    var viewController: UIViewController {
        return tabBarController
    }

    init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
    }

    func embed(_ children: [Scene], customData: [AnyHashable: AnyHashable]?) {
        let childViewControllers = children.map { $0.viewController }
        tabBarController.setViewControllers(childViewControllers, animated: true)
        tabBarController.selectedIndex = customData?["selectedIndex"] as? Int ?? 0
    }
}

class SingleScene: Scene {

    let viewController: UIViewController

    init(viewController: UIViewController) {
        self.viewController = viewController
    }
}
