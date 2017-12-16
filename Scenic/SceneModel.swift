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

    public func selectIndex(_ tabBarIndex: Int, ofTabBar tabBarName: String) -> SceneModel {
        var new = self
        if sceneName == tabBarName {
            new.customData = new.customData ?? [:]
            new.customData?["selectedIndex"] = tabBarIndex
        } else {
            new.children = new.children.map { $0.selectIndex(tabBarIndex, ofTabBar: tabBarName) }
        }
        return new
    }
}
