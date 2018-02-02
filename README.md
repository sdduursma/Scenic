# Scenic

## Introduction

With Scenic, the navigation hierarchy of an app is defined using a simple data structure called a _SceneModel_. For example, this SceneModel defines an app with a UITabBarController which contains a UINavigationController with two child view controllers in the first tab and another view controller in the second tab:

```swift
let mySceneModel = SceneModel(sceneName: "tabBar",
                              children: [SceneModel(sceneName: "stack",
                                                    children: [SceneModel(sceneName: "a"),
                                                               SceneModel(sceneName: "b")],
                                                    customData: nil),
                                         SceneModel(sceneName: "c")],
                              customData: ["selectedIndex": 1])
```

This navigation hierarchy is displayed to the user by setting the root scene model of the _Navigator_:

```swift
myNavigator.setRootSceneModel(mySceneModel)
```

The Navigator will instantiate the required view controllers and compose them as defined by the SceneModel. The navigation hierarchy can be altered simply by setting a new root scene model on the Navigator. The Navigator will automatically determine which view controllers to add and remove in order to realise the new hierarchy.

## Installation
Scenic supports iOS 11+.

### CocoaPods
If you use [CocoaPods][] to manage your dependencies, add Scenic to your `Podfile`:

```
pod 'Scenic'
```

[CocoaPods]: https://cocoapods.org/
