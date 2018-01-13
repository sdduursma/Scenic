import Foundation

class SceneRetainer {

    let sceneName: String

    let scene: Scene

    let children: [SceneRetainer]

    init(sceneName: String, scene: Scene, children: [SceneRetainer]) {
        self.sceneName = sceneName
        self.scene = scene
        self.children = children
    }
}

extension SceneRetainer {

    func sceneRetainer(forSceneName name: String) -> SceneRetainer? {
        if sceneName == name {
            return self
        }
        return children.flatMap { $0.sceneRetainer(forSceneName: name) } .first
    }
}
