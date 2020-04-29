import UIKit

public protocol SceneFactory {

    func makeScene(for sceneName: String) -> Scene?
}

public protocol Scene: class {

    var viewController: UIViewController { get }

    var eventDelegate: EventDelegate? { get set }

    func embed(_ children: [Scene], customData: [AnyHashable: AnyHashable]?)

    // TODO: Pass custom data?
    func prepareForReuse()
}

extension Scene {

    public var eventDelegate: EventDelegate? {
        get {
            return nil
        }
        set { }
    }

    public func embed(_ children: [Scene], customData: [AnyHashable: AnyHashable]?) { }

    public func prepareForReuse() { }
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

    public func embed(_ children: [Scene], customData: [AnyHashable: AnyHashable]?) {
        self.children = children
        let childViewControllers = children.map { $0.viewController }
        navigationController.setViewControllers(childViewControllers, animated: false)
    }

    public func prepareForReuse() {
        navigationController.setViewControllers([], animated: false)
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

    public func prepareForReuse() {
        tabBarController.setViewControllers(nil, animated: false)
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
