import UIKit

public protocol SceneFactory {

    func makeScene(for sceneName: String) -> Scene?
}

public protocol Scene: class {

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

public protocol EventDelegate: class {

    func sendEvent(_ event: NavigationEvent)
}

public class StackScene: NSObject, Scene, UINavigationControllerDelegate {

    private let navigationController: UINavigationController

    private var children: [Scene] = []

    public var viewController: UIViewController {
        return navigationController
    }

    public weak var eventDelegate: EventDelegate?

    public init(navigationController: UINavigationController = UINavigationController()) {
        self.navigationController = navigationController

        super.init()

        navigationController.delegate = self
    }

    public func embed(_ children: [Scene], customData: [AnyHashable: AnyHashable]?) {
        self.children = children
        let childViewControllers = children.map { $0.viewController }
        navigationController.setViewControllers(childViewControllers, animated: false)
    }

    public func navigationController(_ navigationController: UINavigationController,
                                     didShow viewController: UIViewController, animated: Bool) {
        let childViewControllers = children.map { $0.viewController }
        if navigationController.viewControllers == Array(childViewControllers.dropLast()) {
            let toIndex = navigationController.viewControllers.count - 1
            eventDelegate?.sendEvent(NavigationEvent(eventName: "StackScene/didPop",
                                                     customData: ["toIndex": toIndex]))
        }
    }
}

public class TabBarScene: NSObject, Scene, UITabBarControllerDelegate {

    public static let didSelectIndexEventName = "TabBarScene.didSelectIndexEvent".scenicNamespacedName

    private let tabBarController: UITabBarController

    public var viewController: UIViewController {
        return tabBarController
    }

    public weak var eventDelegate: EventDelegate?

    public init(tabBarController: UITabBarController = UITabBarController()) {
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
        guard let selectedIndex = tabBarController.viewControllers?.index(of: viewController) else { return false }
        eventDelegate?.sendEvent(NavigationEvent(eventName: TabBarScene.didSelectIndexEventName, customData: ["selectedIndex": selectedIndex]))
        return false
    }
}

public class SingleScene: Scene {

    public let viewController: UIViewController

    public init(viewController: UIViewController = UIViewController()) {
        self.viewController = viewController
    }
}
