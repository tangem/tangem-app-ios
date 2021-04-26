//
//  SceneDelegate.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    let assembly = Assembly()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let contentView = MainView(viewModel: assembly.getMainViewModel())


        if let activity = connectionOptions.userActivities.first {
            handleActivity(activity)
            scene.userActivity = activity
        }
        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
    
    func scene(_ scene: UIScene, willContinueUserActivityWithType userActivityType: String) {
        guard let activity = scene.userActivity else { return }
        handleActivity(activity)
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handleActivity(userActivity)
        scene.userActivity = userActivity
    }
    
    private func handleActivity(_ activity: NSUserActivity) {
        // Get URL components from the incoming user activity
        guard activity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = activity.webpageURL,
              incomingURL.absoluteString != "https://example.com"
        else { return }
        
        let link = incomingURL.absoluteString
        let batch = incomingURL.lastPathComponent
        assembly.updateAppClipCard(with: batch, fullLink: link)
    }

}

