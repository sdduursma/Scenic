//
//  SceneDelegate.swift
//  ScenicTestHarness
//
//  Created by Samuel Duursma on 25/06/2020.
//  Copyright © 2020 Samuel Duursma. All rights reserved.
//

import UIKit
import Scenic

class ColorViewController: UIViewController {

    let colorName: String

    init(colorName: String) {
        self.colorName = colorName

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = colorName

        let color = nameToColor(colorName) ?? .black
        view.backgroundColor = color
    }
}

private func nameToColor(_ name: String) -> UIColor? {
    let mapping: [String: UIColor] = [
        "red": .red,
        "orange": .orange,
        "yellow": .yellow,
        "green": .green,
        "blue": .blue,
        "magenta": .magenta,
        "purple": .purple,
        "gray": .gray,
        "brown": .brown
    ]
    return mapping[name]
}

class TestSceneFactory: SceneFactory {

    func makeScene(for sceneName: String) -> Scene? {
        switch sceneName {
        case "stack":
            return StackScene()
        case "tabBar":
            return TabBarScene()
        default:
            return SingleScene(viewController: ColorViewController(colorName: sceneName))
        }
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private(set) var navigator: Navigator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let scene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: scene)
        navigator = NavigatorImpl(window: window!, sceneFactory: TestSceneFactory())
        navigator?.set(rootSceneModel: SceneModel(sceneName: "red"))
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}
