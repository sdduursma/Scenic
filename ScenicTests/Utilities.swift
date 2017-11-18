import UIKit
@testable import Scenic

class MockScene: Scene {

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

    private let sceneConstructors: [String: () -> Scene]

    init(scenes: [String: Scene] = [:]) {
        sceneConstructors = scenes.mapValues { scene in return { scene } }
    }

    init(scene constructor: @autoclosure @escaping () -> Scene, for sceneName: String) {
        sceneConstructors = [sceneName: constructor]
    }

    func makeScene(for sceneName: String) -> Scene? {
        return sceneConstructors[sceneName]?()
    }
}

class MockEventDelegate: EventDelegate {

    private(set) var sentEvents: [NavigationEvent] = []

    func sendEvent(_ event: NavigationEvent) {
        sentEvents.append(event)
    }
}
