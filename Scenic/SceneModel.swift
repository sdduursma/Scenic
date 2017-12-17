import Foundation

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

extension SceneModel {

    func withSceneName(_ name: String) -> SceneModel {
        var new = self
        new.sceneName = name
        return new
    }

    func withChildren(_ children: [SceneModel]) -> SceneModel {
        var new = self
        new.children = children
        return new
    }

    func withCustomData(_ customData: [AnyHashable: AnyHashable]?) -> SceneModel {
        var new = self
        new.customData = customData
        return new
    }

    func update(_ name: String, with closure: (SceneModel) -> SceneModel) -> SceneModel {
        if sceneName == name {
            return closure(self)
        }
        return withChildren(children.map { $0.update(name, with: closure)})
    }
}

extension SceneModel {

    public func selectIndex(_ tabBarIndex: Int, ofTabBar tabBarName: String) -> SceneModel {
        return update(tabBarName) { tabBar in
            var customData = tabBar.customData ?? [:]
            customData["selectedIndex"] = tabBarIndex
            return tabBar.withCustomData(customData)
        }
    }
}
