//
//  SceneModelTests.swift
//  ScenicTests
//
//  Created by Samuel Duursma on 16/12/2017.
//  Copyright © 2017 Samuel Duursma. All rights reserved.
//

import XCTest
@testable import Scenic

class SceneModelTests: XCTestCase {

    func testWithName() {
        XCTAssertEqual(SceneModel(sceneName: "a").withSceneName("b"), SceneModel(sceneName: "b"))
    }

    func testWithChildren() {
        XCTAssertEqual(SceneModel(sceneName: "scene", children: [SceneModel(sceneName: "a")])
            .withChildren([SceneModel(sceneName: "b")]),
                       SceneModel(sceneName: "scene", children: [SceneModel(sceneName: "b")]))
    }

    func testWithCustomData() {
        XCTAssertEqual(SceneModel(sceneName: "scene", customData: ["a": "b"]).withCustomData(["c": "d"]),
                       SceneModel(sceneName: "scene", customData: ["c": "d"]))
    }

    func testUpdateNonExisting() {
        let sceneModel = SceneModel(sceneName: "a")
        XCTAssertEqual(sceneModel.update("b") { $0.withSceneName("c") }, sceneModel)
    }

    func testUpdateRoot() {
        let sceneModel = SceneModel(sceneName: "a")
        XCTAssertEqual(sceneModel.update("a") { $0.withSceneName("b") }, SceneModel(sceneName: "b"))
    }

    func testUpdateChild() {
        let sceneModel = SceneModel(sceneName: "a", children: [SceneModel(sceneName: "b")])
        XCTAssertEqual(sceneModel.update("b") { $0.withSceneName("c") },
                       SceneModel(sceneName: "a", children: [SceneModel(sceneName: "c")]))
    }

    func testUpdateOneOfManyChildren() {
        let sceneModel = SceneModel(sceneName: "a",
                                    children: [SceneModel(sceneName: "b"),
                                               SceneModel(sceneName: "c")])
        XCTAssertEqual(sceneModel.update("c") { $0.withSceneName("d") },
                       SceneModel(sceneName: "a",
                                  children: [SceneModel(sceneName: "b"),
                                             SceneModel(sceneName: "d")]))
    }

    func testSelectIndexOfTabBar() {
        let sceneModel = SceneModel(sceneName: "tabBar")
        XCTAssertEqual(sceneModel.selectIndex(1, ofTabBar: "tabBar"),
                       SceneModel(sceneName: "tabBar", customData: ["selectedIndex": 1]))
    }
}
