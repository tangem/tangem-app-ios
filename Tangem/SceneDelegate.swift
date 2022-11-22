//
//  SceneDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import UIKit
import SwiftUI
import TangemSdk
import BlockchainSdk

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private let appCoordinator: AppCoordinator = .init()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        appCoordinator.start(with: .init(connectionOptions: connectionOptions, newScan: false))

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            let appView = AppCoordinatorView(coordinator: appCoordinator)
            window.rootViewController = UIHostingController(rootView: appView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        appCoordinator.scene(scene, continue: userActivity)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        appCoordinator.scene(scene, openURLContexts: URLContexts)
    }
}
