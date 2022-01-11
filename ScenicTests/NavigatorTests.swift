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
        let exp = expectation(description: "")

        // when
        navigator.set(rootSceneModel: rootSceneModel1, completion: {
            exp.fulfill()
        })
        wait(for: [exp], timeout: 10)

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
        XCTAssertEqual(NavigatorImpl.plan(old, new), [.dismiss("a")])
    }

    func testPlanNestedDismissal() {
        let old = SceneModel(sceneName: "a",
                             presented: SceneModel(sceneName: "b",
                                                   presented: SceneModel(sceneName: "c")))
        let new = SceneModel(sceneName: "a")
        XCTAssertEqual(NavigatorImpl.plan(old, new), [.dismiss("a")])
    }

    func testPlanDismiss1Deep() {
        let old = SceneModel(sceneName: "a",
                             presented: SceneModel(sceneName: "b",
                                                   presented: SceneModel(sceneName: "c")))
        let new = SceneModel(sceneName: "a",
                             presented: SceneModel(sceneName: "b"))
        XCTAssertEqual(NavigatorImpl.plan(old, new), [.dismiss("b")])
    }

    func testPlanReplacement() {
        let old = SceneModel(sceneName: "a",
                             presented: SceneModel(sceneName: "b"))
        let new = SceneModel(sceneName: "a",
                             presented: SceneModel(sceneName: "c"))
        XCTAssertEqual(NavigatorImpl.plan(old, new), [.dismiss("a"),
                                                      .present(SceneModel(sceneName: "a",
                                                                          presented: SceneModel(sceneName: "c"))),
                                                      .configure("c", nil)])
    }

    func testPlanReplacePresentedByChild() {
        let old = SceneModel(sceneName: "a",
                             children: [SceneModel(sceneName: "b",
                                                   presented: SceneModel(sceneName: "c"))])
        let new = SceneModel(sceneName: "a",
                             children: [SceneModel(sceneName: "b",
                                                   presented: SceneModel(sceneName: "d"))])
        XCTAssertEqual(NavigatorImpl.plan(old, new), [.dismiss("b"),
                                                      .present(SceneModel(sceneName: "b",
                                                                          presented: SceneModel(sceneName: "d"))),
                                                      .configure("d", nil)])
    }

    func testPlanDismissAndPresentFromSibling() {
        let old = SceneModel(sceneName: "tabBar",
                             children: [SceneModel(sceneName: "red",
                                                   presented: SceneModel(sceneName: "yellow")),
                                        SceneModel(sceneName: "orange")])
        let new = SceneModel(sceneName: "tabBar",
                             children: [SceneModel(sceneName: "red"),
                                        SceneModel(sceneName: "orange",
                                                   presented: SceneModel(sceneName: "green"))])
        XCTAssertEqual(NavigatorImpl.plan(old, new), [.dismiss("red"),
                                                      .present(SceneModel(sceneName: "orange",
                                                                          presented: SceneModel(sceneName: "green"))),
                                                      .configure("green", nil)])
    }

    func testPlanFirstTime() {
        let new = SceneModel(sceneName: "red",
                             children: [SceneModel(sceneName: "orange",
                                                   children: [SceneModel(sceneName: "blue")])],
                             customData: ["foo": "bar"])
        XCTAssertEqual(NavigatorImpl.plan(nil, new), [.embed(SceneModel(sceneName: "orange",
                                                                        children: [SceneModel(sceneName: "blue")])),
                                                      .embed(SceneModel(sceneName: "red",
                                                                        children: [SceneModel(sceneName: "orange",
                                                                                              children: [SceneModel(sceneName: "blue")])],
                                                                        customData: ["foo": "bar"])),
                                                      .configure("blue", nil),
                                                      .configure("orange", nil),
                                                      .configure("red", ["foo": "bar"])])
    }
}
