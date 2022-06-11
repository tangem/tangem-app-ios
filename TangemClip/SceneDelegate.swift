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
    private var userPrefs = UserPrefsService()
    
    var window: UIWindow?
    let assembly = Assembly()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let contentView = MainView(viewModel: assembly.getMainViewModel())

        handle(connectionOptions.userActivities.first, in: scene)
        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handle(userActivity, in: scene)
    }
    
    private func handle(_ activity: NSUserActivity?, in scene: UIScene) {
        // Get URL components from the incoming user activity
        let url: URL
        if let activity = activity, activity.activityType == NSUserActivityTypeBrowsingWeb, let incomingURL = activity.webpageURL {
            if incomingURL.absoluteString == "https://example.com" {
                return
            }
            url = incomingURL
            scene.userActivity = activity
        } else if let savedNdef = URL(string: userPrefs.lastScannedNdef) {
            url = savedNdef
        } else {
            url = URL(string: "https://tangem.com/ndef/CB79")!
        }
        
        let link = url.absoluteString
        let batch = url.lastPathComponent
        assembly.updateAppClipCard(with: batch, fullLink: link)
        userPrefs.lastScannedNdef = link
        if !userPrefs.scannedNdefs.contains(link) {
            userPrefs.scannedNdefs.append(link)
        }
    }

}

