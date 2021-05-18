//
//  SceneDelegate.swift
//  Tangem Tap
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
    let assembly = Assembly()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        assembly.services.walletConnectService.restore()
        // Create the SwiftUI view that provides the window contents.
        assembly.services.userPrefsService.numberOfLaunches += 1
        print("Launch number:", assembly.services.userPrefsService.numberOfLaunches)
     
        let vm = assembly.makeReadViewModel()
        let contentView = ContentView() { ReadView(viewModel: vm) }
        .environmentObject(assembly)
        .environmentObject(assembly.services.navigationCoordinator)
            
        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
        handleActivity(connectionOptions.userActivities)
        handleURL(contexts: connectionOptions.urlContexts)
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handleActivity([userActivity])
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        handleURL(contexts: URLContexts)
    }
    
    private func handleActivity(_ userActivity: Set<NSUserActivity>) {
        guard
            let activity = userActivity.first(where: { $0.activityType == NSUserActivityTypeBrowsingWeb }),
            let url = activity.webpageURL
        else { return }
        
        handleUrl(url)
    }
    
    private func handleURL(contexts: Set<UIOpenURLContext>) {
        if let url = contexts.first?.url {
            handleUrl(url)
        }
    }
    
    private func handleUrl(_ url: URL) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.assembly.services.urlHandlers.forEach {
                $0.handle(url: url)
            }
        }
    }
}

