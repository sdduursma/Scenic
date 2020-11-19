import UIKit

public protocol SceneFactory {

    func makeScene(for sceneName: String) -> Scene?
}

public protocol Scene: class {

    var viewController: UIViewController { get }

    var eventDelegate: EventDelegate? { get set }

    func configure(with customData: [AnyHashable: AnyHashable]?)

//    func didDismissIfNecessary(didDismiss: Bool, customData: [String: AnyHashable])

    func embed(_ children: [Scene], options: [String: AnyHashable]?)
}

extension Scene {

    public var eventDelegate: EventDelegate? {
        get {
            return nil
        }
        set { }
    }

    public func configure(with customData: [AnyHashable: AnyHashable]?) { }

    public func embed(_ children: [Scene], options: [String: AnyHashable]?) { }
}

public struct SceneEvent: Equatable {
    public var eventName: String
    public var customData: [AnyHashable: AnyHashable]? = nil
}

public protocol EventDelegate: class {

    func scene(_ scene: Scene, didPercieve event: SceneEvent)
}

public class StackScene: NSObject, Scene, UINavigationControllerDelegate {

    static let didPopEventName = "StackScene.didPop".scenicNamespacedName

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

    public func embed(_ children: [Scene], options: [String: AnyHashable]?) {
        self.children = children
        let childViewControllers = children.map { $0.viewController }
        let animated = options?["animated".scenicNamespacedName] as? Bool ?? true
        navigationController.setViewControllers(childViewControllers, animated: animated)
    }

    public func navigationController(_ navigationController: UINavigationController,
                                     didShow viewController: UIViewController, animated: Bool) {
        let childViewControllers = children.map { $0.viewController }
        if navigationController.viewControllers == Array(childViewControllers.dropLast()) {
            let toIndex = navigationController.viewControllers.count - 1
            eventDelegate?.scene(self, didPercieve: SceneEvent(eventName: StackScene.didPopEventName,
                                                               customData: ["toIndex": toIndex]))
        }
    }
}

public class TabBarScene: NSObject, Scene, UITabBarControllerDelegate {

    public static let didSelectIndexEventName = "TabBarScene.didSelectIndexEvent".scenicNamespacedName

    private var selectedIndex = 0

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

    public func configure(with customData: [AnyHashable : AnyHashable]?) {
        selectedIndex = customData?["selectedIndex"] as? Int ?? selectedIndex
    }

    public func embed(_ children: [Scene], options: [String: AnyHashable]?) {
        let childViewControllers = children.map { $0.viewController }
        let animated = options?["animated".scenicNamespacedName] as? Bool ?? true
        tabBarController.setViewControllers(childViewControllers, animated: animated)
        tabBarController.selectedIndex = selectedIndex
    }

    public func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard let selectedIndex = tabBarController.viewControllers?.index(of: viewController) else { return false }
        eventDelegate?.scene(self, didPercieve: SceneEvent(eventName: TabBarScene.didSelectIndexEventName, customData: ["selectedIndex": selectedIndex]))
        return false
    }
}

public class SingleScene: Scene {

    public let viewController: UIViewController

    public init(viewController: UIViewController = UIViewController()) {
        self.viewController = viewController
    }
}
