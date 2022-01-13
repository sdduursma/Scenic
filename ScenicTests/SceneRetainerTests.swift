import XCTest
import Nimble
@testable import Scenic

class SceneRetainerTests: XCTestCase {

    func testSceneRetainerForNonExistingSceneName() {
        let sceneRetainer = SceneRetainer(sceneName: "a", scene: MockScene(), children: [])
        expect(sceneRetainer.sceneRetainer(forSceneName: "b")).to(beNil())
    }

    func testSceneRetainerForSceneNameOfSelf() {
        let sceneRetainer = SceneRetainer(sceneName: "a", scene: MockScene(), children: [])
        expect(sceneRetainer.sceneRetainer(forSceneName: "a")).to(beIdenticalTo(sceneRetainer))
    }

    func testSceneRetainerForSceneNameOfChild() {
        let sceneRetainerB = SceneRetainer(sceneName: "b",
                                           scene: MockScene(),
                                           children: [])
        let rootSceneRetainer = SceneRetainer(sceneName: "a",
                                              scene: MockScene(),
                                              children: [sceneRetainerB])
        expect(rootSceneRetainer.sceneRetainer(forSceneName: "b")).to(beIdenticalTo(sceneRetainerB))
    }

    func testSceneRetainerForSceneNameOfNestedChild() {
        let sceneRetainerC = SceneRetainer(sceneName: "c",
                                           scene: MockScene(),
                                           children: [])
        let rootSceneRetainer = SceneRetainer(sceneName: "a",
                                              scene: MockScene(),
                                              children: [SceneRetainer(sceneName: "b",
                                                                       scene: MockScene(),
                                                                       children: [sceneRetainerC])])
        expect(rootSceneRetainer.sceneRetainer(forSceneName: "c")).to(beIdenticalTo(sceneRetainerC))
    }

    func testSceneRetainerForSceneNameOfPresented() {
        let sceneRetainer = SceneRetainer(sceneName: "b",
                                          scene: MockScene(),
                                          children: [])
        let rootSceneRetainer = SceneRetainer(sceneName: "a",
                                              scene: MockScene(),
                                              presented: sceneRetainer)
        expect(rootSceneRetainer.sceneRetainer(forSceneName: "b")).to(beIdenticalTo(sceneRetainer))
    }

    func testSceneRetainerForSceneNameOfNestedPresented() {
        let sceneRetainerC = SceneRetainer(sceneName: "c",
                                           scene: MockScene(),
                                           children: [])
        let rootSceneRetainer = SceneRetainer(sceneName: "a",
                                              scene: MockScene(),
                                              presented: SceneRetainer(sceneName: "b",
                                                                       scene: MockScene(),
                                                                       presented: sceneRetainerC))
        expect(rootSceneRetainer.sceneRetainer(forSceneName: "c")).to(beIdenticalTo(sceneRetainerC))
    }
}
