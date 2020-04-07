import UIKit

extension String {

    var scenicNamespacedName: String {
        return "com.sdduursma.Scenic." + self
    }
}

public protocol Navigator {

    func set(rootSceneModel: SceneModel)

    var events: [NavigationEvent] { get }

    func sendEvent(_ event: NavigationEvent)

    func addEventWatcher(_ watcher: @escaping (NavigationEvent) -> Void)
}

extension Navigator {

    func set(rootSceneModel: SceneModel, _ options: [String: Any]?) {
        set(rootSceneModel: rootSceneModel)
    }
}

public struct NavigationEvent {

    public var eventName: String
    public var customData: [AnyHashable: AnyHashable]?

    public init(eventName: String, customData: [AnyHashable: AnyHashable]? = nil) {
        self.eventName = eventName
        self.customData = customData
    }
}

extension NavigationEvent: Equatable {

    public static func ==(left: NavigationEvent, right: NavigationEvent) -> Bool {
        return left.eventName == right.eventName && isCustomDataEqual(left, right)
    }

    private static func isCustomDataEqual(_ left: NavigationEvent, _ right: NavigationEvent) -> Bool {
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

public class NavigatorImpl: Navigator, EventDelegate {

    public let window: UIWindow

    public let sceneFactory: SceneFactory

    public private(set) var events: [NavigationEvent] = []

    private var eventWatchers: [(NavigationEvent) -> Void] = []

    private var rootSceneRetainer: SceneRetainer?

    public init(window: UIWindow, sceneFactory: SceneFactory) {
        self.window = window
        self.sceneFactory = sceneFactory
    }

    public func set(rootSceneModel: SceneModel, _ options: [String: Any]? = nil) {
        rootSceneRetainer = retainerHierarchy(from: rootSceneModel)
        if let retainer = rootSceneRetainer {
            window.rootViewController = retainer.scene.viewController
            buildViewControllerHierarchy(from: retainer, options)
        }
    }

    public func set(rootSceneModel: SceneModel) {
        set(rootSceneModel: rootSceneModel, nil)
    }

    private func retainerHierarchy(from sceneModel: SceneModel) -> SceneRetainer? {
        let retainer: SceneRetainer?
        if let scene = aquireScene(for: sceneModel.sceneName) {
            scene.eventDelegate = self
            var children: [SceneRetainer] = []
            for childSceneModel in sceneModel.children {
                if let childSceneRetainer = retainerHierarchy(from: childSceneModel) {
                    children.append(childSceneRetainer)
                }
            }
            let presented = sceneModel.presented.flatMap { retainerHierarchy(from: $0) }
            retainer = SceneRetainer(sceneName: sceneModel.sceneName,
                                     scene: scene,
                                     children: children,
                                     presented: presented,
                                     customData: sceneModel.customData)
        } else {
            retainer = nil
        }
        return retainer
    }

    private func buildViewControllerHierarchy(from retainer: SceneRetainer, _ options: [String: Any]? = nil) {
        let animated = (options?["animated"] as? Bool) == true
        let scene = retainer.scene
        scene.embed(retainer.children.map { $0.scene }, customData: retainer.customData)
        if scene.viewController.presentedViewController != nil
            && scene.viewController.presentedViewController != retainer.presented?.scene.viewController {
            scene.viewController.dismiss(animated: animated) {
                if let presented = retainer.presented {
                    // TODO: Parametrise animated
                    scene.viewController.present(presented.scene.viewController, animated: animated) { [weak self] in
                        self?.buildViewControllerHierarchy(from: presented)
                    }
                }
            }
        }
        if let presented = retainer.presented {
            // TODO: Parametrise animated
            scene.viewController.present(presented.scene.viewController, animated: animated) { [weak self] in
                self?.buildViewControllerHierarchy(from: presented)
            }
        }
        for child in retainer.children {
            buildViewControllerHierarchy(from: child)
        }
    }

    private func aquireScene(for sceneName: String) -> Scene? {
        return rootSceneRetainer?.sceneRetainer(forSceneName: sceneName)?.scene ??
            sceneFactory.makeScene(for: sceneName)
    }

    public func sendEvent(_ event: NavigationEvent) {
        events.append(event)
        eventWatchers.forEach { $0(event) }
    }

    public func addEventWatcher(_ watcher: @escaping (NavigationEvent) -> Void) {
        eventWatchers.append(watcher)
    }
}
