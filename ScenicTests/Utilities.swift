import UIKit
@testable import Scenic

class MockScene: Scene {

    let viewController: UIViewController

    var eventDelegate: EventDelegate?

    private(set) var children: [Scene] = []

    private(set) var customData: [AnyHashable: AnyHashable]?

    init(viewController: UIViewController = UIViewController()) {
        self.viewController = viewController
    }

    func embed(_ children: [Scene], customData: [AnyHashable: AnyHashable]?) {
        self.children = children
        self.customData = customData
    }

    func triggerEvent() {
        eventDelegate?.scene(self, didPercieve: SceneEvent(eventName: "MockScene/event"))
    }
}

class MockSceneFactory: SceneFactory {

    private let sceneConstructors: [String: () -> Scene]

    init(scenes constructors: [String: () -> Scene]) {
        sceneConstructors = constructors
    }

    convenience init(scenes: [String: Scene] = [:]) {
        self.init(scenes: scenes.mapValues { scene in return { scene } })
    }

    convenience init(scene: Scene, for sceneName: String) {
        self.init(scenes: [sceneName: scene])
    }

    func makeScene(for sceneName: String) -> Scene? {
        return sceneConstructors[sceneName]?()
    }
}

class MockEventDelegate: EventDelegate {

    private(set) var sentEvents: [SceneEvent] = []

    func scene(_ scene: Scene, didPercieve event: SceneEvent) {
        sentEvents.append(event)
    }
}
