import XCTest
import Nimble
@testable import Scenic

class NavigatorTests: XCTestCase {

    func testSetRootSceneEmbedsScenes() {
        // given
        let window = UIWindow()
        let scenes: [String: MockScene] = [
            "red": MockScene(),
            "orange": MockScene(),
            "blue": MockScene()
        ]
        let sceneFactory = MockSceneFactory(scenes: scenes)
        let navigator = NavigatorImpl(window: window, sceneFactory: sceneFactory)
        let rootSceneModel1 = SceneModel(sceneName: "red",
                                             children: [SceneModel(sceneName: "orange",
                                                                       children: [SceneModel(sceneName: "blue")])],
                                             customData: ["foo": "bar"])

        // when
        navigator.set(rootSceneModel: rootSceneModel1)

        // then
        XCTAssertTrue(scenes["red"]!.children[0] as! MockScene === scenes["orange"]!)
        guard let redSceneCustomData = scenes["red"]!.customData else {
            XCTFail()
            return
        }
        XCTAssertEqual(redSceneCustomData, ["foo": "bar"])
        XCTAssertTrue(scenes["orange"]!.children[0] as! MockScene === scenes["blue"]!)
    }

    func testSetRootSceneSetsWindowRootViewController() {
        // given
        let window = UIWindow()
        let rootScene = MockScene()
        let sceneFactory = MockSceneFactory(scenes: ["root": rootScene])
        let navigator = NavigatorImpl(window: window, sceneFactory: sceneFactory)

        // when
        navigator.set(rootSceneModel: SceneModel(sceneName: "root"))

        // then
        XCTAssertEqual(window.rootViewController, rootScene.viewController)
    }

    func testSendEvents() {
        let navigator = NavigatorImpl(window: UIWindow(), sceneFactory: MockSceneFactory())
        navigator.sendEvent(NavigationEvent(eventName: "TabBarScene/didSelectIndex"))
        expect(navigator.events).to(contain(NavigationEvent(eventName: "TabBarScene/didSelectIndex")))
    }

    func testWatchEventsSentByScene() {
        let scene = MockScene()
        let navigator = NavigatorImpl(window: UIWindow(), sceneFactory: MockSceneFactory(scene: scene, for: "scene"))
        navigator.set(rootSceneModel: SceneModel(sceneName: "scene"))
        scene.triggerEvent()
        expect(navigator.events).to(contain(NavigationEvent(eventName: "MockScene/event")))
    }

    func testRetainsRootScene() {
        // given
        var scene: Scene? = MockScene()
        weak var weakScene = scene
        let sceneFactory = MockSceneFactory(scene: scene!, for: "scene0")
        let navigator = NavigatorImpl(window: UIWindow(), sceneFactory: sceneFactory)
        let sceneModel = SceneModel(sceneName: "scene0")

        // when
        navigator.set(rootSceneModel: sceneModel)
        scene = nil

        // then
        XCTAssertNotNil(weakScene)
    }
}
