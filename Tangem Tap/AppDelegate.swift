//
//  AppDelegate.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var loadingView: UIView? = nil
    
    func addLoadingView() {
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            let view = UIView(frame: window.bounds)
            view.backgroundColor = UIColor.init(white: 0.0, alpha: 0.6)
            let indicator = UIActivityIndicatorView(style: .medium)
            view.addSubview(indicator)
            indicator.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
            indicator.startAnimating()
            window.addSubview(view)
            window.bringSubviewToFront(view)
            loadingView = view
        }
    }
    
    func removeLoadingView() {
        loadingView?.removeFromSuperview()
        loadingView = nil
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UISwitch.appearance().onTintColor = .tangemTapBlue
        UITableView.appearance().backgroundColor = .clear
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().barTintColor = UIColor.tangemTapBgGray
        UINavigationBar.appearance().tintColor = UIColor.tangemTapGrayDark6
        
        
        
        if #available(iOS 14.0, *) {
            // iOS 14 doesn't have extra separators below the list by default.
        } else {
            // To remove only extra separators below the list:
            UITableView.appearance().tableFooterView = UIView()
        }

        #if DEBUG
        Firebase.Analytics.setAnalyticsCollectionEnabled(false)
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
        #else
          FirebaseApp.configure()
//        Firebase.Analytics.setAnalyticsCollectionEnabled(utils.isAnalytycsEnabled) //[REDACTED_TODO_COMMENT]
//        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(utils.isAnalytycsEnabled)
        #endif
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

