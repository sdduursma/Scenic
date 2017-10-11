import UIKit
@testable import Scenic

class MockScene: Scene {

    var sceneRef: String?

    let viewController: UIViewController

    private(set) var children: [Scene] = []

    private(set) var customData: [AnyHashable: AnyHashable]?

    init(viewController: UIViewController = UIViewController()) {
        self.viewController = viewController
    }

    func embed(_ children: [Scene], customData: [AnyHashable: AnyHashable]?) {
        self.children = children
        self.customData = customData
    }
}

class MockSceneFactory: SceneFactory {

    private let scenes: [String: Scene]

    init(scenes: [String: Scene] = [:]) {
        self.scenes = scenes
    }

    func makeScene(for sceneName: String) -> Scene? {
        return scenes[sceneName]
    }
}

class MockEventDelegate: EventDelegate {

    private(set) var sentEvents: [NavigationEvent] = []

    func sendEvent(_ event: NavigationEvent) {
        sentEvents.append(event)
    }
}
