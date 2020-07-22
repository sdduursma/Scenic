import UIKit

extension String {

    var scenicNamespacedName: String {
        return "com.sdduursma.Scenic." + self
    }
}

public protocol Navigator {

    func send(rootSceneModel: SceneModel, options: [String: AnyHashable]?, completion: (() -> Void)?)

    func set(rootSceneModel: SceneModel)

    var events: [NavigationEvent] { get }

    func sendEvent(_ event: NavigationEvent)

    func addEventWatcher(_ watcher: @escaping (NavigationEvent) -> Void)
}

extension Navigator {

    func set(rootSceneModel: SceneModel, _ options: [String: AnyHashable]?) {
        set(rootSceneModel: rootSceneModel)
    }
}

public struct NavigationEvent {

    public var eventName: String
    public var sceneName: String
    // TODO: Add rootSceneModel
    public var customData: [AnyHashable: AnyHashable]?

    public init(eventName: String, sceneName: String, customData: [AnyHashable: AnyHashable]? = nil) {
        self.eventName = eventName
        self.sceneName = sceneName
        self.customData = customData
    }
}

extension NavigationEvent: Equatable {

    public static func ==(left: NavigationEvent, right: NavigationEvent) -> Bool {
        return left.sceneName == right.sceneName
            && left.eventName == right.eventName
            && isCustomDataEqual(left, right)
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

    private let serial = DispatchQueue(label: "com.sdduursma.Scenic.Navigator/serial")

    private var eventWatchers: [(NavigationEvent) -> Void] = []

    private var hierarchy: SceneModel?

    private var rootSceneRetainer: SceneRetainer?

    private var sceneToName: [ObjectIdentifier: String] = [:]

    public init(window: UIWindow, sceneFactory: SceneFactory) {
        self.window = window
        self.sceneFactory = sceneFactory
    }

    /// Asynchronously sets the new scene hierarchy. This operation is thread-safe.
    public func send(rootSceneModel: SceneModel, options: [String: AnyHashable]?, completion: (() -> Void)?) {
        serial.async { [weak self] in
            // TODO: Call completion handler if self is nil?
            guard let self = self else { return }

            let group = DispatchGroup()
            group.enter()

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.set(rootSceneModel: rootSceneModel, options) {
                    group.leave()
                }
            }

            group.wait()

            completion?()
        }
    }

    public func set(rootSceneModel: SceneModel, _ options: [String: AnyHashable]? = nil, completion: (() -> Void)? = nil) {
        guard rootSceneModel != hierarchy else {
            completion?()
            return
        }
        let oldHierarchy = hierarchy
        hierarchy = rootSceneModel
        sceneToName = [:]
        rootSceneRetainer = retainerHierarchy(from: rootSceneModel)
        if let retainer = rootSceneRetainer {
            window.rootViewController = retainer.scene.viewController
            buildViewControllerHierarchy(from: retainer, oldHierarchy: oldHierarchy, newHierarchy: rootSceneModel, options: options, completion)
        } else {
            completion?()
        }
    }

    public func set(rootSceneModel: SceneModel) {
        set(rootSceneModel: rootSceneModel, nil)
    }

    private func retainerHierarchy(from sceneModel: SceneModel) -> SceneRetainer? {
        let retainer: SceneRetainer?
        if let scene = acquireScene(for: sceneModel.sceneName) {
            sceneToName[ObjectIdentifier(scene)] = sceneModel.sceneName
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

    /// Must be called on the main thread.
    private func buildViewControllerHierarchy(from retainer: SceneRetainer, oldHierarchy: SceneModel?, newHierarchy: SceneModel, options: [String: AnyHashable]? = nil, _ completion: (() -> Void)? = nil) {
        let group = DispatchGroup()
        _buildViewControllerHierarchy(from: retainer, oldHierarchy: oldHierarchy, newHierarchy: newHierarchy, group: group, options)
        group.notify(queue: .main) {
            completion?()
        }
    }

    /// Must be called on the main thread.
    private func _buildViewControllerHierarchy(from retainer: SceneRetainer, oldHierarchy: SceneModel?, newHierarchy: SceneModel, group: DispatchGroup, _ options: [String: AnyHashable]? = nil) {
        group.enter()
        let animated = (options?["animated"] as? Bool) == true
        let scene = retainer.scene
        scene.configure(with: retainer.customData)
        scene.embed(retainer.children.map { $0.scene }, options: options)
        if newHierarchy.presented != oldHierarchy?.presented {
            if oldHierarchy?.presented == nil, let presented = retainer.presented {
                // Present new presented
                // TODO: Dismiss any currently presented VC?
                group.enter()
                scene.viewController.present(presented.scene.viewController, animated: animated, completion: { [weak self] in
                    // TODO: No force unwrap
                    self?._buildViewControllerHierarchy(from: presented, oldHierarchy: nil, newHierarchy: newHierarchy.presented!, group: group)
                    group.leave()
                })
            } else if newHierarchy.presented == nil {
                // Dismiss old presented
                if let presentedVc = scene.viewController.presentedViewController,
                   !presentedVc.isBeingDismissed {
                    group.enter()
                    scene.viewController.dismiss(animated: animated, completion: {
                        group.leave()
                    })
                }
            } else if let presented = retainer.presented {
                // Replace old presented with new presented
                if let oldPresentedVc = scene.viewController.presentedViewController,
                   !oldPresentedVc.isBeingDismissed {
                    // Dismiss any VC that's currently presented.
                    group.enter()
                    scene.viewController.dismiss(animated: animated, completion: {
                        scene.viewController.present(presented.scene.viewController, animated: animated, completion: { [weak self] in
                            // TODO: No force unwrap
                            self?._buildViewControllerHierarchy(from: presented, oldHierarchy: nil, newHierarchy: newHierarchy.presented!, group: group)
                            group.leave()
                        })
                    })
                } else {
                    // Directly present the new VC.
                    group.enter()
                    scene.viewController.present(presented.scene.viewController, animated: animated, completion: { [weak self] in
                        // TODO: No force unwrap
                        self?._buildViewControllerHierarchy(from: presented, oldHierarchy: nil, newHierarchy: newHierarchy.presented!, group: group)
                        group.leave()
                    })
                }
            }
        }
//        if let presented = scene.viewController.presentedViewController,
//            presented.presentingViewController == retainer.scene.viewController
//            && presented != retainer.presented?.scene.viewController {
//            group.enter()
//            scene.viewController.dismiss(animated: animated) {
//                if let presented = retainer.presented {
//                    group.enter()
//                    scene.viewController.present(presented.scene.viewController, animated: animated) { [weak self] in
//                        self?._buildViewControllerHierarchy(from: presented, group: group, options)
//                        group.leave()
//                    }
//                }
//                group.leave()
//            }
//        } else if let presented = retainer.presented {
//            if presented.scene.viewController != scene.viewController.presentedViewController {
//                group.enter()
//                scene.viewController.present(presented.scene.viewController, animated: animated) { [weak self] in
//                    self?._buildViewControllerHierarchy(from: presented, group: group, options)
//                    group.leave()
//                }
//            } else {
//                _buildViewControllerHierarchy(from: presented, group: group, options)
//            }
//        }
        for child in retainer.children {
            let oldChildSceneModel = oldHierarchy?.children.filter { $0.sceneName == child.sceneName }.first
            // TODO: Don't force unwrap
            let newChildSceneModel = newHierarchy.children.filter { $0.sceneName == child.sceneName }.first!
            _buildViewControllerHierarchy(from: child, oldHierarchy: oldChildSceneModel, newHierarchy: newChildSceneModel, group: group, options)
        }
        group.leave()
    }

    private func acquireScene(for sceneName: String) -> Scene? {
        if let scene = rootSceneRetainer?.sceneRetainer(forSceneName: sceneName)?.scene {
            return scene
        }
        return sceneFactory.makeScene(for: sceneName)
    }

    public func sendEvent(_ event: NavigationEvent) {
        events.append(event)
        eventWatchers.forEach { $0(event) }
    }

    public func scene(_ scene: Scene, didPercieve sceneEvent: SceneEvent) {
        guard let sceneName = sceneName(for: scene) else {
            NSLog("[Scenic] Inconsistency warning: scene \(scene) does not appear in the scene hierarchy")
            return
        }
        let event = NavigationEvent(eventName: sceneEvent.eventName,
                                    sceneName: sceneName,
                                    customData: sceneEvent.customData)
        events.append(event)
        eventWatchers.forEach { $0(event) }
    }

    public func addEventWatcher(_ watcher: @escaping (NavigationEvent) -> Void) {
        eventWatchers.append(watcher)
    }

    private func sceneName(for scene: Scene) -> String? {
        sceneToName[ObjectIdentifier(scene)]
    }
}
