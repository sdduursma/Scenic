import UIKit

protocol Navigator {

    func set(rootSceneModel: SceneModel)
}

class NavigatorImpl: Navigator {

    let window: UIWindow

    let sceneFactory: SceneFactory

    init(window: UIWindow, sceneFactory: SceneFactory) {
        self.window = window
        self.sceneFactory = sceneFactory
    }

    func set(rootSceneModel: SceneModel) {
        let rootScene = configureScene(for: rootSceneModel)
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
}
