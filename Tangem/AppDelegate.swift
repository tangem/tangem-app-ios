//
//  AppDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Yulia Moskaleva. All rights reserved.
//

import UIKit

extension UIApplication {
    
    static func navigationManager() -> NavigationManager {
        return (self.shared.delegate as! AppDelegate).navigationManager!
    }
    
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var navigationManager: NavigationManager?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        initializeNavigationManager()
        
        // Override point for customization after application launch.
        let attrs = [
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular),
            NSAttributedStringKey.foregroundColor: UIColor.white
        ]
        UINavigationBar.appearance().titleTextAttributes = attrs
        UINavigationBar.appearance().barStyle = .blackOpaque
        UINavigationBar.appearance().tintColor = .white
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = navigationManager?.navigationController
        window.makeKeyAndVisible()
        
        self.window = window
        
        return true
    }
    
    func initializeNavigationManager() {
        let storyBoard = UIStoryboard(name: "Reader", bundle: nil)
        guard let rootViewController = storyBoard.instantiateInitialViewController()  else {
            assertionFailure()
            return
        }
        
        navigationManager = NavigationManager(rootViewController: rootViewController)
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb else {
            return false
        }
        
        if #available(iOS 12, *) {
            return checkUserActivityForBackgroundNFC(userActivity)
        }
        
        return true
    }
    
    @available(iOS 12.0, *)
    func checkUserActivityForBackgroundNFC(_ userActivity: NSUserActivity) -> Bool {
        
        let ndefMessage = userActivity.ndefMessagePayload
        guard ndefMessage.records.count > 0,
            ndefMessage.records[0].typeNameFormat != .empty else {
                return false
        }
        
        return true
    }
    
    
    

}

