//
//  ScenicTestHarnessTests.swift
//  ScenicTestHarnessTests
//
//  Created by Samuel Duursma on 25/06/2020.
//  Copyright © 2020 Samuel Duursma. All rights reserved.
//

import XCTest
import Scenic
@testable import ScenicTestHarness

class ScenicTestHarnessTests: XCTestCase {

    private var navigator: NavigatorImpl {
        let sceneDelegate = UIApplication.shared.connectedScenes.first!.delegate! as! SceneDelegate
        return sceneDelegate.navigator as! NavigatorImpl
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

//        let exp = expectation(description: "")
//        navigator.set(rootSceneModel: SceneModel(sceneName: "white"), ["animated": true], completion: {
//            exp.fulfill()
//        })
//        wait(for: [exp], timeout: 20)
    }

    func testReplacePresented() throws {
        let exp1 = expectation(description: "")
        navigator.send(rootSceneModel: SceneModel(sceneName: "red",
                                                  presented: SceneModel(sceneName: "orange",
                                                                        presented: SceneModel(sceneName: "yellow"))),
                       options: ["animated": true]) {
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 20)

        let exp2 = expectation(description: "")
        navigator.send(rootSceneModel: SceneModel(sceneName: "red",
                                                  presented: SceneModel(sceneName: "orange",
                                                                        presented: SceneModel(sceneName: "green"))),
                       options: ["animated": true]) {
            exp2.fulfill()
        }
        wait(for: [exp2], timeout: 20)
    }

    func testSetSimpleSceneModel() throws {
        let exp = expectation(description: "")
        navigator.send(rootSceneModel: SceneModel(sceneName: "red"), options: nil) {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 20)
    }

    func testPlanDismissAndPresentFromSibling() throws {
        // TODO: This test will cause an error like the following to be logged:
        // Presenting view controllers on detached view controllers is discouraged <ScenicTestHarness.ColorViewController: 0x7fc2a2421ec0>.

        let exp1 = expectation(description: "")
        navigator.send(rootSceneModel: SceneModel(sceneName: "tabBar",
                                                  children: [SceneModel(sceneName: "red",
                                                                        presented: SceneModel(sceneName: "yellow")),
                                                             SceneModel(sceneName: "orange")]),
                       options: ["animated": true]) {
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 20)

        let exp2 = expectation(description: "")
        navigator.send(rootSceneModel: SceneModel(sceneName: "tabBar",
                                                  children: [SceneModel(sceneName: "red"),
                                                             SceneModel(sceneName: "orange",
                                                                        presented: SceneModel(sceneName: "green"))],
                                                  customData: ["selectedIndex": 1]),
                       options: ["animated": true]) {
            exp2.fulfill()
        }
        wait(for: [exp2], timeout: 20)
    }
}
