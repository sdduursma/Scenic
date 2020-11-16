import UIKit
import os

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
        print("[Scenic] banana hammock")
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
        // TODO: If these are not equal, that could mean that a child is not equal
        if newHierarchy.presented != oldHierarchy?.presented {
            if oldHierarchy?.presented?.sceneName != newHierarchy.presented?.sceneName {
                if oldHierarchy?.presented == nil, let presented = retainer.presented {
                    // Present new presented
                    // TODO: Dismiss any currently presented VC?
                    group.enter()
                    // TODO: Improve logging
                    let vc = "\(presented.scene.viewController.title ?? "\(presented.scene.viewController)")"
                    NSLog("[Scenic] present view controller: " + vc)
                    scene.viewController.present(presented.scene.viewController, animated: animated, completion: { [weak self] in
                        // TODO: No force unwrap
                        self?._buildViewControllerHierarchy(from: presented, oldHierarchy: nil, newHierarchy: newHierarchy.presented!, group: group, options)
                        group.leave()
                    })
                } else if newHierarchy.presented == nil {
                    // Dismiss old presented
                    if let presentedVc = scene.viewController.presentedViewController,
                       !presentedVc.isBeingDismissed {
                        NSLog("[Scenic] dismiss view controller: " + presentedVc.toScenicDebugString())
                        group.enter()
                        scene.viewController.dismiss(animated: animated, completion: {
                            group.leave()
                        })
                    } else {
                        NSLog("[Scenic] unable to dismiss view controller")
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
                        // TODO: Wait until old VC is dismissed?
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

    static func plan(_ old: SceneModel?, _ new: SceneModel) -> [AnyHashable] {
        var steps: [AnyHashable] = []
        if let old = old {
            // TODO: inout?
            steps.append(contentsOf: dismissals(old, new))
        }
        steps.append(contentsOf: embedSteps(old, new))
//        steps.append(contentsOf: configurations(old, new))
        if let p = presentationStep(old, new) {
            steps.append(p)
            steps.append(contentsOf: plan(nil, findPresented(new)!))
        } else if let presented = findPresented(new) {
            steps.append(contentsOf: plan(findPresented(old!)!, presented))
        }
        return steps
    }

    // TODO: Should old be optional ?
    /// Compares `old` and `new`. ...
    static func dismissals(_ old: SceneModel, _ new: SceneModel?) -> [AnyHashable] {
        let steps: [AnyHashable]
        if old == new {
            steps = []
        } else {
            let dismissal: AnyHashable?
            let childDismissals: [AnyHashable]
            if old.sceneName != new?.sceneName {
                if old.presented != nil {
                    dismissal = Dismissal(old.sceneName)
                } else {
                    dismissal = nil
                }
                childDismissals = dismissals(old.children, nil)
            } else {
                if let oldPresentedName = old.presented?.sceneName,
                   oldPresentedName != new?.presented?.sceneName {
                    dismissal = Dismissal(old.sceneName)
                } else {
                    dismissal = nil
                }
                childDismissals = dismissals(old.children, new?.children)
            }

            steps = (dismissal.map { [$0] } ?? []) + childDismissals
        }
        return steps
    }

    static func dismissals(_ oldChildren: [SceneModel], _ newChildren: [SceneModel]?) -> [AnyHashable] {
        var childDismissals: [AnyHashable] = []
        for (i, oldChild) in oldChildren.enumerated() {
            let newChild: SceneModel?
            if i < newChildren?.count ?? 0 {
                newChild = newChildren![i]
            } else {
                newChild = nil
            }
            // TODO: Will there be tail recursion?
            childDismissals.append(contentsOf: dismissals(oldChild, newChild))
        }
        return childDismissals
    }

    private static func embedSteps(_ old: SceneModel?, _ new: SceneModel) -> [AnyHashable] {
        var steps: [AnyHashable] = []
        embedSteps(old, new, &steps)
        return steps
    }

    // TODO: Does `inout` really provide better performance than returning?
    private static func embedSteps(_ old: SceneModel?, _ new: SceneModel, _ steps: inout [AnyHashable]) {
        if old == new {
            return
        } else {
            if !new.children.isEmpty {
                // Embed steps are performed depth-first.
                embedSteps(old?.children, new.children, &steps)
                if (old?.sceneName != new.sceneName || old?.children.map(\.sceneName) != new.children.map(\.sceneName)) {
                    steps.append(EmbedStep(new))
                }
            }
        }
    }

    private static func embedSteps(_ oldChildren: [SceneModel]?, _ newChildren: [SceneModel], _ steps: inout [AnyHashable]) {
        for (i, newChild) in newChildren.enumerated() {
            let oldChild: SceneModel?
            if let oldChildren = oldChildren,
               i < oldChildren.count {
                oldChild = oldChildren[i]
            } else {
                oldChild = nil
            }
            embedSteps(oldChild, newChild, &steps)
        }
    }

    static func configurations(_ old: SceneModel?, _ new: SceneModel) -> [AnyHashable] {
        return []
    }

    static func presentationStep(_ old: SceneModel?, _ new: SceneModel) -> AnyHashable? {
        let step: AnyHashable?
        if old == new {
            step = nil
        } else {
            if new.presented != nil && (old?.sceneName != new.sceneName || old?.presented?.sceneName != new.presented?.sceneName) {
                step = PresentationStep(new)
            } else {
                step = presentationStep(old?.children, new.children)
            }
        }
        return step
    }

    static func presentationStep(_ oldChildren: [SceneModel]?, _ newChildren: [SceneModel]) -> AnyHashable? {
        for (i, newChild) in newChildren.enumerated() {
            let oldChild: SceneModel?
            // TODO Coalesce?
            if i < oldChildren?.count ?? 0 {
                oldChild = oldChildren![i]
            } else {
                oldChild = nil
            }
            if let step = presentationStep(oldChild, newChild) {
                return step
            }
        }
        return nil
    }

    static func findPresented(_ sceneModel: SceneModel) -> SceneModel? {
        if let p = sceneModel.presented {
            return p
        }
        return findPresented(sceneModel.children)
    }

    static func findPresented(_ sceneModels: [SceneModel]) -> SceneModel? {
        for s in sceneModels {
            if let p = findPresented(s) {
                return p
            }
        }
        return nil
    }

    /// Compares `old` and `new`. If the root scene of `old` or any child of the root presents a scene and it doesn't present that seen anymore in `new`, the presented scene is dismissed.
    private func dismissIfNeeded(_ old: SceneModel, _ new: SceneModel, _ completion: (() -> Void)?) {
        if old != new {
            if old.presented != new.presented {
                if old.presented?.sceneName != new.presented?.sceneName && old.presented != nil {
                    dismiss(old, completion)
                } else {
                    completion?()
                }
            } else {
                let group = DispatchGroup()
                // TODO: Use a kind of outer zip
                for (oc, nc) in zip(old.children, new.children) {
                    group.enter()
                    dismissIfNeeded(oc, nc, {
                        group.leave()
                    })
                }
                // TODO: Should completion even be optional here?
                // TODO: Does `group` need to be retained by an outer scope or is it
                // sufficient to capture it with the closure above.
                completion.map { group.notify(queue: .main, execute: $0) }
            }
        } else {
            completion?()
        }
    }

    private func dismiss(_ sceneModel: SceneModel, _ completion: (() -> Void)? = nil) {
        // TODO: This shouldn't be acquire because there's no reason to instantiate a scene.
        guard let scene = acquireScene(for: sceneModel.sceneName) else {
            // TODO
            NSLog("[Scenic] Inconsistency warning")
            return
        }
        // TODO: Options
        scene.viewController.dismiss(animated: true, completion: completion)
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

//func outerZip()

// TODO: Should conform to Hashable.
protocol BuildStep: Hashable {

    func execute(/* some args */ _ completion: (() -> Void)?)
}

struct PresentationStep: BuildStep {

    var target: SceneModel

    init(_ target: SceneModel) {
        self.target = target
    }

    func execute(_ completion: (() -> Void)?) {
    }
}

struct EmbedStep: BuildStep {

    var target: SceneModel

    init(_ target: SceneModel) {
        self.target = target
    }

    func execute(_ completion: (() -> Void)?) {
    }
}

struct Dismissal: BuildStep {

    /// The name of the target scene.
    var target: String

    init(_ target: String) {
        self.target = target
    }

    func execute(_ completion: (() -> Void)?) {
    }
}

protocol ScenicDebugStringConvertible {

    func toScenicDebugString() -> String
}

extension UIViewController: ScenicDebugStringConvertible {

    func toScenicDebugString() -> String {
        return title ?? "\(self)"
    }
}

//func printS(_ message: String, _ args: Any?...) -> String {
//    var message
//}
