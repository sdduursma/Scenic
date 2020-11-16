import Foundation

fileprivate class Box<T> {

    fileprivate let value: T

    fileprivate init(_ value: T) {
        self.value = value
    }
}

extension Box: Equatable where T: Equatable {

    static func == (lhs: Box<T>, rhs: Box<T>) -> Bool {
        lhs.value == rhs.value
    }
}

extension Box: Hashable where T: Hashable {

    func hash(into hasher: inout Hasher) {
        value.hash(into: &hasher)
    }
}

public struct SceneModel: Hashable {

    public var sceneName: String
    public var children: [SceneModel]

    private var _presented: Box<SceneModel>?

    /// The SceneModel that is presented by this SceneModel.
    public var presented: SceneModel? {
        get {
            _presented?.value
        } set(newVal) {
            _presented = newVal.map { Box($0) }
        }
    }

    public var customData: [AnyHashable: AnyHashable]?

    public init(sceneName: String,
                children: [SceneModel] = [],
                presented: SceneModel? = nil,
                customData: [AnyHashable: AnyHashable]? = nil) {
        self.sceneName = sceneName
        self.children = children
        self._presented = presented.map { Box($0) }
        self.customData = customData
    }
}

extension SceneModel {

    public func withSceneName(_ name: String) -> SceneModel {
        var new = self
        new.sceneName = name
        return new
    }

    public func withChildren(_ children: [SceneModel]) -> SceneModel {
        var new = self
        new.children = children
        return new
    }

    public func withPresented(_ presented: SceneModel?) -> SceneModel {
        var new = self
        new.presented = presented
        return new
    }

    public func withCustomData(_ customData: [AnyHashable: AnyHashable]?) -> SceneModel {
        var new = self
        new.customData = customData
        return new
    }

    public func update(_ name: String, with closure: (SceneModel) -> SceneModel) -> SceneModel {
        if sceneName == name {
            return closure(self)
        }
        return withChildren(children.map { $0.update(name, with: closure)})
    }
}

extension SceneModel {

    public func applyTabBarDidSelectIndex(event: NavigationEvent) -> SceneModel {
        if event.eventName == TabBarScene.didSelectIndexEventName,
            let index = event.customData?["selectedIndex"] as? Int {
            return selectIndex(index, ofTabBar: event.sceneName)
        }
        return self
    }

    public func applyTabBarDidSelectIndex(to tabBarName: String, event: NavigationEvent) -> SceneModel {
        if event.eventName == TabBarScene.didSelectIndexEventName,
            let index = event.customData?["selectedIndex"] as? Int {
            return selectIndex(index, ofTabBar: tabBarName)
        }
        return self
    }

    public func selectIndex(_ tabBarIndex: Int, ofTabBar tabBarName: String) -> SceneModel {
        return update(tabBarName) { tabBar in
            var customData = tabBar.customData ?? [:]
            customData["selectedIndex"] = tabBarIndex
            return tabBar.withCustomData(customData)
        }
    }
}

extension SceneModel {

    public func applyStackDidPop(event: NavigationEvent) -> SceneModel {
        if event.eventName == StackScene.didPopEventName,
            let toIndex = event.customData?["toIndex"] as? Int {
            return popStack(event.sceneName, to: toIndex)
        }
        return self
    }

    public func applyStackDidPop(to stackName: String, event: NavigationEvent) -> SceneModel {
        if event.eventName == StackScene.didPopEventName,
            let toIndex = event.customData?["toIndex"] as? Int {
            return popStack(stackName, to: toIndex)
        }
        return self
    }

    public func popStack(_ stackName: String, to index: Int) -> SceneModel {
        return update(stackName) { stack in
            guard stack.children.indices.contains(index) else { return stack }
            return stack.withChildren(Array(stack.children.prefix(through: index)))
        }
    }
}
