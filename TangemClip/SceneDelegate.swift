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

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        var batch: String?
        var link: String = ""
        defer {
            assembly.updateAppClipCard(with: batch, fullLink: link)
        }
        
        // Get URL components from the incoming user activity
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL
        else { return }
        
        link = incomingURL.absoluteString
        batch = incomingURL.lastPathComponent
    }

}

