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

public struct SceneModel {

    public var sceneName: String
    public var children: [SceneModel]
    public var customData: [AnyHashable: AnyHashable]?

    public init(sceneName: String,
         children: [SceneModel] = [],
         customData: [AnyHashable: AnyHashable]? = nil) {
        self.sceneName = sceneName
        self.children = children
        self.customData = customData
    }
}

extension SceneModel: Equatable {

    public static func ==(left: SceneModel, right: SceneModel) -> Bool {
        return left.sceneName == right.sceneName && left.children == right.children && isCustomDataEqual(left, right)
    }

    private static func isCustomDataEqual(_ left: SceneModel, _ right: SceneModel) -> Bool {
        if let leftCustomData = left.customData,
            let rightCustomData = right.customData,
            leftCustomData == rightCustomData {
            return true
        } else if left.customData == nil && right.customData == nil {
            return true
        } else {
            return false
        }
    }
}

public class StackScene: Scene {

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
        guard let selectedIndex = tabBarController.viewControllers?.index(of: viewController) else { return false }
        eventDelegate?.sendEvent(NavigationEvent(eventName: "TabBarScene/didSelectIndex", customData: ["selectedIndex": selectedIndex]))
        return false
    }
}

extension SceneModel {

    func selectIndex(_ index: Int, ofTabBar tabBarName: String) -> SceneModel {
        guard sceneName == tabBarName else { return self }
        var new = self
        new.customData = new.customData ?? [:]
        new.customData?["selectedIndex"] = index
        return new
    }
}

public class SingleScene: Scene {

    public let viewController: UIViewController

    public init(viewController: UIViewController) {
        self.viewController = viewController
    }
}
