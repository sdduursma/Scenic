# Scenic

## Introduction

With Scenic, the navigation hierarchy of an app is defined using a simple data structure called a _SceneModel_. For example, this SceneModel defines an app with a UITabBarController which contains a UINavigationController with two child view controllers in the first tab and another view controller in the second tab:

```swift
let mySceneModel = SceneModel(sceneName: "tabBar",
                              children: [SceneModel(sceneName: "stack",
                                                    children: [SceneModel(sceneName: "cats"),
                                                               SceneModel(sceneName: "cat",
                                                                          customData: ["catName": "Fred"])]),
                                         SceneModel(sceneName: "settings")],
                              customData: ["selectedIndex": 1])
```

This navigation hierarchy is displayed to the user by setting the root scene model of the _Navigator_:

```swift
myNavigator.setRootSceneModel(mySceneModel)
```

The Navigator will instantiate the required view controllers and compose them as defined by the SceneModel. The navigation hierarchy can be altered simply by setting a new root scene model on the Navigator. The Navigator will automatically determine which view controllers to add and remove in order to realise the new hierarchy.

## Usage guide

### Installation
Scenic supports iOS 11+.

#### CocoaPods
If you use [CocoaPods][] to manage your dependencies, add Scenic to your `Podfile`:

```
pod 'Scenic'
```

### Integrating Scenic into an app

Each app using Scenic will have an instance of `Navigator` which manages the navigation hierarchy. A good place to instantiate this object is in the the application delegate:

```swift
import UIKit
import Scenic

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private var navigator: Navigator?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow()
        self.window = window
        navigator = NavigatorImpl(window: window, sceneFactory: MySceneFactory())

        // ...
    }
```

`NavigatorImpl` is initialized with an instance of `SceneFactory`. The scene factory is responsible for instantiating a scene given a scene name.

### The state of the scenes is a function of the SceneModel

As much as possible, scenes prohibit their associated view controller's navigation related state from changing. For example, when the user attempts to select a tab of a `UITabBarController`, the `TabBarScene` prohibits the `UITabBarController`'s selected index from changing and instead sends an _event_. The app can then perceive this event and update the scene model to change the selected index and/or perform any other actions. This ensures that the scene's state is always a function of the scene model.

### Perceiving events from scenes

To perceive these events, add an event watcher to the `Navigator`:

```swift
myNavigator.addEventWatcher { event in
    // do something
}
```

### Some state changes cannot be prohibited

Some state changes, like a user going back in a `UINavigationController`'s stack, cannot be prohibited because iOS doesn't provide any means to do so. In this case, the `Navigator` will emit an event describing the change but the application is responsible for applying the approriate change to the scene model, to ensure that the scene model stays in sync with the state of the scenes.

Scenic provides functions to make this easier, like `SceneModel.applyStackDidPop(to:event:)`.


[CocoaPods]: https://cocoapods.org/
