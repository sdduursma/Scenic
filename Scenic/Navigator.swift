import UIKit

public protocol Navigator {

    func set(rootSceneModel: SceneModel)

    func sendEvent(_ event: NavigationEvent)

    func addEventWatcher(_ watcher: @escaping (NavigationEvent) -> Void)
}

public struct NavigationEvent {

    public var sceneRef: String
    public var eventName: String
    public var customData: [AnyHashable: AnyHashable]?

    public init(sceneRef: String, eventName: String, customData: [AnyHashable: AnyHashable]? = nil) {
        self.sceneRef = sceneRef
        self.eventName = eventName
        self.customData = customData
    }
}

extension NavigationEvent: Equatable {

    public static func ==(left: NavigationEvent, right: NavigationEvent) -> Bool {
        let isCustomDataEqual: Bool
        if let leftCustomData = left.customData,
            let rightCustomData = right.customData,
            leftCustomData == rightCustomData {
            isCustomDataEqual = true
        } else if left.customData == nil && right.customData == nil {
            isCustomDataEqual = true
        } else {
            isCustomDataEqual = false
        }
        return left.sceneRef == right.sceneRef &&
            left.eventName == right.eventName &&
            isCustomDataEqual
    }
}

public class NavigatorImpl: Navigator {

    public let window: UIWindow

    public let sceneFactory: SceneFactory

    private var eventWatchers: [(NavigationEvent) -> Void] = []

    private var rootScene: Scene?

    public init(window: UIWindow, sceneFactory: SceneFactory) {
        self.window = window
        self.sceneFactory = sceneFactory
    }

    public func set(rootSceneModel: SceneModel) {
        rootScene = configureScene(for: rootSceneModel)
        window.rootViewController = rootScene?.viewController
    }

    private func configureScene(for sceneModel: SceneModel) -> Scene? {
        guard let scene = sceneFactory.makeScene(for: sceneModel.sceneName) else { return nil }
        var children: [Scene] = []
        for childSceneModel in sceneModel.children {
            if let childScene = configureScene(for: childSceneModel) {
                children.append(childScene)
            }
        }
        scene.embed(children, customData: sceneModel.customData)
        return scene
    }

    public func sendEvent(_ event: NavigationEvent) {
        eventWatchers.forEach { $0(event) }
    }

    public func addEventWatcher(_ watcher: @escaping (NavigationEvent) -> Void) {
        eventWatchers.append(watcher)
    }
}
