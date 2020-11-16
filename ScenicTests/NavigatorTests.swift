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

    func testWatchEventsSentByScene() {
        let scene = MockScene()
        let navigator = NavigatorImpl(window: UIWindow(), sceneFactory: MockSceneFactory(scene: scene, for: "scene"))
        navigator.set(rootSceneModel: SceneModel(sceneName: "scene"))
        scene.triggerEvent()
        expect(navigator.events).to(contain(NavigationEvent(eventName: "MockScene/event", sceneName: "scene")))
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

    func testPersistsScenes() {
        // given
        let window = UIWindow()
        let sceneFactory = MockSceneFactory(scenes: ["a": { StackScene() }, "b": { SingleScene() }])
        let navigator = NavigatorImpl(window: window, sceneFactory: sceneFactory)
        navigator.set(rootSceneModel: SceneModel(sceneName: "a", children: [SceneModel(sceneName: "b")]))
        let viewControllerA0 = window.rootViewController
        let viewControllerB0 = viewControllerA0?.childViewControllers.first

        // when
        navigator.set(rootSceneModel: SceneModel(sceneName: "a", children: [SceneModel(sceneName: "b")]))

        // then
        let viewControllerA1 = window.rootViewController
        let viewControllerB1 = viewControllerA1?.childViewControllers.first
        expect(viewControllerA0).to(beIdenticalTo(viewControllerA1))
        expect(viewControllerB0).to(beIdenticalTo(viewControllerB1))
    }

    func testPlanSimpleDismissal() {
        let old = SceneModel(sceneName: "a", presented: SceneModel(sceneName: "b"))
        let new = SceneModel(sceneName: "a")
        XCTAssertEqual(NavigatorImpl.plan(old, new), [Dismissal("a")])
    }

    func testPlanNestedDismissal() {
        let old = SceneModel(sceneName: "a",
                             presented: SceneModel(sceneName: "b",
                                                   presented: SceneModel(sceneName: "c")))
        let new = SceneModel(sceneName: "a")
        XCTAssertEqual(NavigatorImpl.plan(old, new), [Dismissal("a")])
    }

    func testPlanDismiss1Deep() {
        let old = SceneModel(sceneName: "a",
                             presented: SceneModel(sceneName: "b",
                                                   presented: SceneModel(sceneName: "c")))
        let new = SceneModel(sceneName: "a",
                             presented: SceneModel(sceneName: "b"))
        XCTAssertEqual(NavigatorImpl.plan(old, new), [Dismissal("b")])
    }

    func testPlanReplacement() {
        let old = SceneModel(sceneName: "a",
                             presented: SceneModel(sceneName: "b"))
        let new = SceneModel(sceneName: "a",
                             presented: SceneModel(sceneName: "c"))
        XCTAssertEqual(NavigatorImpl.plan(old, new), [Dismissal("a"),
                                                      PresentationStep(SceneModel(sceneName: "a",
                                                                                  presented: SceneModel(sceneName: "c")))])
    }

    func testPlanReplacePresentedByChild() {
        let old = SceneModel(sceneName: "a",
                             children: [SceneModel(sceneName: "b",
                                                   presented: SceneModel(sceneName: "c"))])
        let new = SceneModel(sceneName: "a",
                             children: [SceneModel(sceneName: "b",
                                                   presented: SceneModel(sceneName: "d"))])
        XCTAssertEqual(NavigatorImpl.plan(old, new), [Dismissal("b"),
                                                      PresentationStep(SceneModel(sceneName: "b",
                                                                                  presented: SceneModel(sceneName: "d")))])
    }
}
