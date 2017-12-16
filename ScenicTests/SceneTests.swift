import XCTest
import Nimble
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

    func testStackSceneAssignsDelegate() {
        let navigationController = UINavigationController()
        let stackScene = StackScene(navigationController: navigationController)
        // Use `stackScene` to silence not used warning while retaining `tabBarScene` in memory.
        _ = stackScene
        XCTAssertNotNil(navigationController.delegate)
    }

    func testStackSceneNavigationControllerDidShowAndPopped() {
        // given
        let navigationController = UINavigationController()
        let stackScene = StackScene(navigationController: navigationController)
        let scene0 = SingleScene(viewController: UIViewController())
        let scene1 = SingleScene(viewController: UIViewController())
        stackScene.embed([scene0, scene1], customData: nil)
        let eventDelegate = MockEventDelegate()
        stackScene.eventDelegate = eventDelegate

        // when
        navigationController.viewControllers.removeLast()
        stackScene.navigationController(navigationController,
                                        didShow: scene0.viewController,
                                        animated: true)

        // then
        expect(eventDelegate.sentEvents).to(contain(NavigationEvent(eventName: "StackScene/didPop",
                                                                    customData: ["toIndex": 0])))
    }

    func testStackSceneNavigationControllerDidShowButDidNotPop() {
        // given
        let navigationController = UINavigationController()
        let stackScene = StackScene(navigationController: navigationController)
        let scene0 = SingleScene(viewController: UIViewController())
        let scene1 = SingleScene(viewController: UIViewController())
        stackScene.embed([scene0, scene1], customData: nil)
        let eventDelegate = MockEventDelegate()
        stackScene.eventDelegate = eventDelegate

        // when
        stackScene.navigationController(navigationController,
                                        didShow: scene1.viewController,
                                        animated: true)

        // then
        expect(eventDelegate.sentEvents).toNot(containElementSatisfying({ event in
            return event.eventName == "StackScene/didPop"
        }))
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
        XCTAssertTrue(eventDelegate.sentEvents.contains(NavigationEvent(eventName: "TabBarScene/didSelectIndex",
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
