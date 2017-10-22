import XCTest
@testable import Scenic

class SceneTests: XCTestCase {

    func testStackSceneEmbedsChildren() {
        // given
        let navigationController = UINavigationController()
        let stackScene = StackScene(navigationController: navigationController)
        let scene0 = SingleScene(viewController: UIViewController())
        let scene1 = SingleScene(viewController: UIViewController())

        // when
        stackScene.embed([scene0, scene1], customData: nil)

        // then
        XCTAssertEqual(navigationController.viewControllers, [scene0.viewController, scene1.viewController])
    }

    func testTabBarSceneEmbedsChildren() {
        // given
        let tabBarController = UITabBarController()
        let tabBarScene = TabBarScene(tabBarController: tabBarController)
        let scene0 = SingleScene(viewController: UIViewController())
        let scene1 = SingleScene(viewController: UIViewController())

        // when
        tabBarScene.embed([scene0, scene1], customData: ["selectedIndex": 1])

        // then
        guard let childViewControllers = tabBarController.viewControllers else {
            XCTFail("Unexpectedly found nil")
            return
        }
        XCTAssertEqual(childViewControllers, [scene0.viewController, scene1.viewController])
        XCTAssertEqual(tabBarController.selectedIndex, 1)
    }

    func testTabBarSceneSelectsDefaultIndex() {
        // given
        let tabBarController = UITabBarController()
        let tabBarScene = TabBarScene(tabBarController: tabBarController)
        let scene0 = SingleScene(viewController: UIViewController())
        let scene1 = SingleScene(viewController: UIViewController())

        // when
        tabBarScene.embed([scene0, scene1], customData: ["selectedIndex": 1])
        tabBarScene.embed([scene0, scene1], customData: nil)

        // then
        XCTAssertEqual(tabBarController.selectedIndex, 0)
    }

    func testTabBarSceneSelectIndex() {
        // given
        let tabBarController = UITabBarController()
        let tabBarScene = TabBarScene(tabBarController: tabBarController)
        let sceneRef = "ac21c1"
        tabBarScene.sceneRef = sceneRef
        let eventDelegate = MockEventDelegate()
        tabBarScene.eventDelegate = eventDelegate
        let scene0 = SingleScene(viewController: UIViewController())
        let viewController1 = UIViewController()
        let scene1 = SingleScene(viewController: viewController1)
        tabBarScene.embed([scene0, scene1], customData: nil)

        // when
        let shouldSelect = tabBarScene.tabBarController(tabBarController, shouldSelect: viewController1)

        // then
        XCTAssertFalse(shouldSelect)
        XCTAssertTrue(eventDelegate.sentEvents.contains(NavigationEvent(sceneRef: sceneRef,
                                                                        eventName: "TabBarScene/didSelectIndex",
                                                                        customData: ["selectedIndex": 1])))
    }

    func testTabBarSceneAssignsDelegate() {
        // given
        let tabBarController = UITabBarController()

        // when
        let tabBarScene = TabBarScene(tabBarController: tabBarController)
        // Use `tabBarScene` to silence not used warning while retaining `tabBarScene` in memory.
        _ = tabBarScene

        // then
        XCTAssertNotNil(tabBarController.delegate)
    }
}
