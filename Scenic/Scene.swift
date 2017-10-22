import UIKit

public protocol SceneFactory {

    func makeScene(for sceneName: String) -> Scene?
}

public protocol Scene: class {

    var sceneRef: String? { get set }

    var viewController: UIViewController { get }

    var eventDelegate: EventDelegate? { get set }

    func embed(_ children: [Scene], customData: [AnyHashable: AnyHashable]?)
}

extension Scene {

    public var eventDelegate: EventDelegate? {
        get {
            return nil
        }
        set { }
    }

    public func embed(_ children: [Scene], customData: [AnyHashable: AnyHashable]?) { }
}

public protocol SceneModel {

    var sceneName: String { get set }
    var children: [SceneModel] { get set }
    var presented: SceneModel? { get set }
    var customData: [AnyHashable: AnyHashable]? { get set }
}

public protocol EventDelegate: class {

    func sendEvent(_ event: NavigationEvent)
}

public struct SceneModelImpl: SceneModel {

    public var sceneName: String
    public var children: [SceneModel]
    public var presented: SceneModel?
    public var customData: [AnyHashable: AnyHashable]?

    public init(sceneName: String,
         children: [SceneModel] = [],
         presented: SceneModel? = nil,
         customData: [AnyHashable: AnyHashable]? = nil) {
        self.sceneName = sceneName
        self.children = children
        self.presented = presented
        self.customData = customData
    }
}

public class StackScene: Scene {

    public var sceneRef: String?

    private let navigationController: UINavigationController

    public var viewController: UIViewController {
        return navigationController
    }

    public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    public func embed(_ children: [Scene], customData: [AnyHashable: AnyHashable]?) {
        let childViewControllers = children.map { $0.viewController }
        navigationController.setViewControllers(childViewControllers, animated: false)
    }
}

public class TabBarScene: NSObject, Scene, UITabBarControllerDelegate {

    public var sceneRef: String?

    private let tabBarController: UITabBarController

    public var viewController: UIViewController {
        return tabBarController
    }

    public weak var eventDelegate: EventDelegate?

    public init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController

        super.init()

        tabBarController.delegate = self
    }

    public func embed(_ children: [Scene], customData: [AnyHashable: AnyHashable]?) {
        let childViewControllers = children.map { $0.viewController }
        tabBarController.setViewControllers(childViewControllers, animated: true)
        tabBarController.selectedIndex = customData?["selectedIndex"] as? Int ?? 0
    }

    public func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard let sceneRef = sceneRef,
            let selectedIndex = tabBarController.viewControllers?.index(of: viewController) else { return false }
        eventDelegate?.sendEvent(NavigationEvent(sceneRef: sceneRef, eventName: "TabBarScene/didSelectIndex", customData: ["selectedIndex": selectedIndex]))
        return false
    }
}

public class SingleScene: Scene {

    public var sceneRef: String?

    public let viewController: UIViewController

    public init(viewController: UIViewController) {
        self.viewController = viewController
    }
}
