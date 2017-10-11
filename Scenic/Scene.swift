import UIKit

protocol SceneFactory {

    func makeScene(for sceneName: String) -> Scene?
}

protocol Scene {

    var sceneRef: String? { get set }

    var viewController: UIViewController { get }

    var eventDelegate: EventDelegate? { get set }

    func embed(_ children: [Scene], customData: [AnyHashable: AnyHashable]?)
}

extension Scene {

    var eventDelegate: EventDelegate? {
        get {
            return nil
        }
        set { }
    }

    func embed(_ children: [Scene], customData: [AnyHashable: AnyHashable]?) { }
}

protocol SceneModel {

    var sceneName: String { get set }
    var children: [SceneModel] { get set }
    var presented: SceneModel? { get set }
    var customData: [AnyHashable: AnyHashable]? { get set }
}

protocol EventDelegate: class {

    func sendEvent(_ event: NavigationEvent)
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

    var sceneRef: String?

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

class TabBarScene: NSObject, Scene, UITabBarControllerDelegate {

    var sceneRef: String?

    private let tabBarController: UITabBarController

    var viewController: UIViewController {
        return tabBarController
    }

    weak var eventDelegate: EventDelegate?

    init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
    }

    func embed(_ children: [Scene], customData: [AnyHashable: AnyHashable]?) {
        let childViewControllers = children.map { $0.viewController }
        tabBarController.setViewControllers(childViewControllers, animated: true)
        tabBarController.selectedIndex = customData?["selectedIndex"] as? Int ?? 0
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard let sceneRef = sceneRef,
            let selectedIndex = tabBarController.viewControllers?.index(of: viewController) else { return false }
        eventDelegate?.sendEvent(NavigationEvent(sceneRef: sceneRef, eventName: "TabBarScene/didSelectIndex", customData: ["selectedIndex": selectedIndex]))
        return false
    }
}

class SingleScene: Scene {

    var sceneRef: String?

    let viewController: UIViewController

    init(viewController: UIViewController) {
        self.viewController = viewController
    }
}
