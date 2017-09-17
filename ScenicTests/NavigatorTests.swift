import XCTest
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
        let rootSceneModel1 = SceneModelImpl(sceneName: "red",
                                             children: [SceneModelImpl(sceneName: "orange",
                                                                       children: [SceneModelImpl(sceneName: "blue")])])

        // when
        navigator.set(rootSceneModel: rootSceneModel1)

        // then
        XCTAssertTrue(scenes["red"]!.children[0] as! MockScene === scenes["orange"]!)
        XCTAssertTrue(scenes["orange"]!.children[0] as! MockScene === scenes["blue"]!)
    }

    func testSetRootSceneSetsWindowRootViewController() {
        // given
        let window = UIWindow()
        let rootScene = MockScene()
        let sceneFactory = MockSceneFactory(scenes: ["root": rootScene])
        let navigator = NavigatorImpl(window: window, sceneFactory: sceneFactory)

        // when
        navigator.set(rootSceneModel: SceneModelImpl(sceneName: "root"))

        // then
        XCTAssertEqual(window.rootViewController, rootScene.viewController)
    }
}

