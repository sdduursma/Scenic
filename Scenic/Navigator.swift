import UIKit

public protocol Navigator {

    func set(rootSceneModel: SceneModel)

    var events: [NavigationEvent] { get }

    func sendEvent(_ event: NavigationEvent)

    func addEventWatcher(_ watcher: @escaping (NavigationEvent) -> Void)
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

    public func set(rootSceneModel: SceneModel) {
        rootSceneRetainer = configureScene(for: rootSceneModel)
        window.rootViewController = rootSceneRetainer?.scene.viewController
    }

    private func configureScene(for sceneModel: SceneModel) -> SceneRetainer? {
        guard let scene = sceneFactory.makeScene(for: sceneModel.sceneName) else { return nil }
        scene.eventDelegate = self
        var children: [SceneRetainer] = []
        for childSceneModel in sceneModel.children {
            if let childSceneRetainer = configureScene(for: childSceneModel) {
                children.append(childSceneRetainer)
            }
        }
        let sceneRetainer = SceneRetainer(scene: scene, children: children)
        scene.embed(children.map { $0.scene }, customData: sceneModel.customData)
        return sceneRetainer
    }

    public func sendEvent(_ event: NavigationEvent) {
        events.append(event)
        eventWatchers.forEach { $0(event) }
    }

    public func addEventWatcher(_ watcher: @escaping (NavigationEvent) -> Void) {
        eventWatchers.append(watcher)
    }
}

class SceneRetainer {

    let scene: Scene

    let children: [SceneRetainer]

    init(scene: Scene, children: [SceneRetainer]) {
        self.scene = scene
        self.children = children
    }
}
