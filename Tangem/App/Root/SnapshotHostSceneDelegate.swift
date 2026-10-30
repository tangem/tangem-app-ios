//
//  SnapshotHostSceneDelegate.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UIKit

final class SnapshotHostSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        self.window = window
    }
}
