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

    private var navigator: Navigator {
        let sceneDelegate = UIApplication.shared.connectedScenes.first!.delegate! as! SceneDelegate
        return sceneDelegate.navigator!
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSetSimpleSceneModel() throws {
        let exp = expectation(description: "")
        navigator.send(rootSceneModel: SceneModel(sceneName: "red"), options: nil) {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
    }
}
