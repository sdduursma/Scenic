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

    func testSelectIndexOfNonExistingTabBar() {
        let sceneModel = SceneModel(sceneName: "scene")
        XCTAssertEqual(sceneModel.selectIndex(1, ofTabBar: "tabBar"), sceneModel)
    }

    func testSelectIndexOfRootTabBar() {
        let sceneModel = SceneModel(sceneName: "tabBar")
        XCTAssertEqual(sceneModel.selectIndex(1, ofTabBar: "tabBar"),
                       SceneModel(sceneName: "tabBar", customData: ["selectedIndex": 1]))
    }

    func testSelectIndexOfChildTabBar() {
        let sceneModel = SceneModel(sceneName: "container", children: [SceneModel(sceneName: "tabBar")])
        XCTAssertEqual(sceneModel.selectIndex(1, ofTabBar: "tabBar"),
                       SceneModel(sceneName: "container", children: [SceneModel(sceneName: "tabBar", customData: ["selectedIndex": 1])]))
    }

    func testSelectIndexOfOneOfManyChildTabBars() {
        let sceneModel = SceneModel(sceneName: "container", children: [SceneModel(sceneName: "tabBar0"), SceneModel(sceneName: "tabBar1")])
        XCTAssertEqual(sceneModel.selectIndex(1, ofTabBar: "tabBar1"),
                       SceneModel(sceneName: "container", children: [SceneModel(sceneName: "tabBar0"), SceneModel(sceneName: "tabBar1", customData: ["selectedIndex": 1])]))
    }
}
