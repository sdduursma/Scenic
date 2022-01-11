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

public extension Navigator {

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
            // TODO: plan to return [BuildStep]
            let plan = NavigatorImpl.plan(oldHierarchy, rootSceneModel)
            materialize(plan, completion)
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

    static func plan(_ old: SceneModel?, _ new: SceneModel) -> [MaterializationStep] {
        var steps: [MaterializationStep] = []
        if let old = old {
            // TODO: inout?
            steps.append(contentsOf: dismissSteps(old, new))
        }
        embedSteps(old, new, &steps)
        configurationSteps(old, new, &steps)
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
    static func dismissSteps(_ old: SceneModel, _ new: SceneModel?) -> [MaterializationStep] {
        let steps: [MaterializationStep]
        if old == new {
            steps = []
        } else {
            let dismissal: MaterializationStep?
            let childDismissals: [MaterializationStep]
            if old.sceneName != new?.sceneName {
                if old.presented != nil {
                    dismissal = MaterializationStep.dismiss(old.sceneName)
                } else {
                    dismissal = nil
                }
                childDismissals = dismissSteps(old.children, nil)
            } else {
                if let oldPresentedName = old.presented?.sceneName,
                   oldPresentedName != new?.presented?.sceneName {
                    dismissal = MaterializationStep.dismiss(old.sceneName)
                } else {
                    dismissal = nil
                }
                childDismissals = dismissSteps(old.children, new?.children)
            }

            steps = (dismissal.map { [$0] } ?? []) + childDismissals
        }
        return steps
    }

    static func dismissSteps(_ oldChildren: [SceneModel], _ newChildren: [SceneModel]?) -> [MaterializationStep] {
        var childDismissals: [MaterializationStep] = []
        for (i, oldChild) in oldChildren.enumerated() {
            let newChild: SceneModel?
            if i < newChildren?.count ?? 0 {
                newChild = newChildren![i]
            } else {
                newChild = nil
            }
            // TODO: Will there be tail recursion?
            childDismissals.append(contentsOf: dismissSteps(oldChild, newChild))
        }
        return childDismissals
    }

    private static func embedSteps(_ old: SceneModel?, _ new: SceneModel) -> [MaterializationStep] {
        var steps: [MaterializationStep] = []
        embedSteps(old, new, &steps)
        return steps
    }

    // TODO: Does `inout` really provide better performance than returning?
    private static func embedSteps(_ old: SceneModel?, _ new: SceneModel, _ steps: inout [MaterializationStep]) {
        if old == new {
            return
        } else {
            if !new.children.isEmpty {
                // Embed steps are performed depth-first.
                // TODO: If old?.sceneName != new.sceneName, embedSteps should be called with old as nil
                embedSteps(old?.children, new.children, &steps)
                if (old?.sceneName != new.sceneName || old?.children.map(\.sceneName) != new.children.map(\.sceneName)) {
                    steps.append(MaterializationStep.embed(new))
                }
            }
        }
    }

    private static func embedSteps(_ oldChildren: [SceneModel]?, _ newChildren: [SceneModel], _ steps: inout [MaterializationStep]) {
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

    static func configurationSteps(_ old: SceneModel?, _ new: SceneModel, _ steps: inout [MaterializationStep]) {
        if old == new {
            return
        } else {
            if !new.children.isEmpty {
                configurationSteps(old?.children, new.children, &steps)
            }
            if old?.sceneName != new.sceneName || old?.customData != new.customData {
                steps.append(MaterializationStep.configure(new.sceneName, new.customData))
            }
        }
    }

    static func configurationSteps(_ oldChildren: [SceneModel]?, _ newChildren: [SceneModel], _ steps: inout [MaterializationStep]) {
        for (i, newChild) in newChildren.enumerated() {
            let oldChild: SceneModel?
            if i < oldChildren?.count ?? 0 {
                oldChild = oldChildren![i]
            } else {
                oldChild = nil
            }
            configurationSteps(oldChild, newChild, &steps)
        }
    }

    static func presentationStep(_ old: SceneModel?, _ new: SceneModel) -> MaterializationStep? {
        let step: MaterializationStep?
        if old == new {
            step = nil
        } else {
            if new.presented != nil && (old?.sceneName != new.sceneName || old?.presented?.sceneName != new.presented?.sceneName) {
                step = MaterializationStep.present(new) //PresentationStep(new)
            } else {
                step = presentationStep(old?.children, new.children)
            }
        }
        return step
    }

    static func presentationStep(_ oldChildren: [SceneModel]?, _ newChildren: [SceneModel]) -> MaterializationStep? {
        for (i, newChild) in newChildren.enumerated() {
            let oldChild: SceneModel?
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

    func getScene(for sceneName: String) -> Scene? {
        rootSceneRetainer?.sceneRetainer(forSceneName: sceneName)?.scene
    }

    // TODO: private
    /// If a scene object corresponding to the given scene name exists, returns it. Otherwise instantiates a new scene object.
    func acquireScene(for sceneName: String) -> Scene? {
        getScene(for: sceneName) ?? sceneFactory.makeScene(for: sceneName)
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

    private func materialize(_ plan: [MaterializationStep],
                         _ completion: (() -> Void)? = nil) {
        if let step = plan.first {
            step.materialize(self, { [weak self] in
                // TODO: This could blow the stack.
                // dropFirst() is efficient, but returns an ArraySlice.
                self?.materialize(plan.dropFirst(), completion)
            })
        } else {
            completion?()
        }
    }

    // TODO: Can we reduce the duplication?
    private func materialize(_ plan: ArraySlice<MaterializationStep>,
                         _ completion: (() -> Void)? = nil) {
        if let step = plan.first {
            step.materialize(self, { [weak self] in
                // TODO: This could blow the stack.
                // dropFirst() is efficient, but returns an ArraySlice.
                self?.materialize(plan.dropFirst(), completion)
            })
        } else {
            completion?()
        }
    }
}

enum MaterializationStep: Hashable {
    case dismiss(_ target: String)
    case embed(_ target: SceneModel)
    case configure(_ target: String, _ customData: [AnyHashable: AnyHashable]?)
    case present(_ target: SceneModel)

    func materialize(_ navigator: NavigatorImpl, _ completion: (() -> Void)?) {
        switch self {
        case .dismiss(let target):
            MaterializationStep.dismiss(navigator, target, completion)
        case .embed(let target):
            MaterializationStep.embed(navigator, target, completion)
        case .configure(let target, let customData):
            MaterializationStep.configure(navigator, target, customData, completion)
        case .present(let target):
            MaterializationStep.present(navigator, target, completion)
        }
    }

    static func dismiss(_ navigator: NavigatorImpl, _ target: String, _ completion: (() -> Void)?) {
        // TODO: Crash or warn if scene is nil?
        let targetScene = navigator.getScene(for: target)
        if let presented = targetScene?.viewController.presentedViewController, !presented.isBeingDismissed {
            // TODO: animated option
            targetScene?.viewController.dismiss(animated: true, completion: completion)
        }
    }

    static func embed(_ navigator: NavigatorImpl, _ target: SceneModel, _ completion: (() -> Void)?) {
        // TODO: Crash or warn if scene is nil?
        let targetScene = navigator.acquireScene(for: target.sceneName)
        let childScenes = target.children.compactMap { navigator.acquireScene(for: $0.sceneName) }
        // TODO: Options
        targetScene?.embed(childScenes, options: [:])
        completion?()
    }

    static func configure(_ navigator: NavigatorImpl, _ target: String, _ customData: [AnyHashable: AnyHashable]?, _ completion: (() -> Void)?) {
        // TODO: Crash or warn if scene is nil?
        let scene = navigator.getScene(for: target)
        scene?.configure(with: customData)
        completion?()
    }

    static func present(_ navigator: NavigatorImpl, _ target: SceneModel, _ completion: (() -> Void)?) {
        // TODO: Crash or warn if scene is nil?
        let targetScene = navigator.acquireScene(for: target.sceneName)!
        let presentedScene = navigator.acquireScene(for: target.presented!.sceneName)!
        // TODO: animated option
        targetScene.viewController.present(presentedScene.viewController, animated: true, completion: completion)
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
