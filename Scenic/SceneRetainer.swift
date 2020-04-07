import Foundation

class SceneRetainer {

    let sceneName: String

    let scene: Scene

    let children: [SceneRetainer]

    let presented: SceneRetainer?

    let customData: [AnyHashable: AnyHashable]?

    init(sceneName: String,
         scene: Scene,
         children: [SceneRetainer] = [],
         presented: SceneRetainer? = nil,
         customData: [AnyHashable: AnyHashable]? = nil) {
        self.sceneName = sceneName
        self.scene = scene
        self.children = children
        self.presented = presented
        self.customData = customData
    }
}

extension SceneRetainer {

    func sceneRetainer(forSceneName name: String) -> SceneRetainer? {
        if sceneName == name {
            return self
        }
        for child in children {
            if let retainer = child.sceneRetainer(forSceneName: name) {
                return retainer
            }
        }
        return presented?.sceneRetainer(forSceneName: name)
    }
}
