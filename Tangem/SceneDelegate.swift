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
        appCoordinator.start(with: .init(connectionOptions: connectionOptions))

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            let appView = AppCoordinatorView(coordinator: appCoordinator)
            let cardViewModel = CardViewModel(cardInfo: CardInfo(card: .card, isTangemNote: false, isTangemWallet: true))
            let details = DetailsView(viewModel: DetailsViewModel(cardModel: cardViewModel, coordinator: DetailsCoordinator(dismissAction: {

            }, popToRootAction: { _ in

            })))
            window.rootViewController = UIHostingController(rootView: details)
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        appCoordinator.scene(scene, continue: userActivity)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        appCoordinator.sceneDidBecomeActive(scene)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        appCoordinator.sceneWillResignActive(scene)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        appCoordinator.scene(scene, openURLContexts: URLContexts)
    }
}
