import UIKit
@testable import Scenic

class MockScene: Scene {

    let viewController: UIViewController

    private(set) var children: [Scene] = []

    init(viewController: UIViewController = UIViewController()) {
        self.viewController = viewController
    }

    func embed(_ children: [Scene]) {
        self.children = children
    }
}

class MockSceneFactory: SceneFactory {

    private let scenes: [String: Scene]

    init(scenes: [String: Scene]) {
        self.scenes = scenes
    }

    func makeScene(for sceneName: String) -> Scene? {
        return scenes[sceneName]
    }
}
