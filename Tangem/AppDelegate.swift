//
//  AppDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import TangemKit
import TangemSdk

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
        window.rootViewController = CardManager.isNFCAvailable ? navigationManager?.navigationController : instantiateStub()
        window.makeKeyAndVisible()
        self.window = window
        #if BETA
            Fabric.with([Crashlytics.self])
        #endif
        Utils().initialize(legacyMode: NfcUtils.isLegacyDevice)
        
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
    
    func instantiateStub() -> UIViewController {
        let sb = UIStoryboard(name: "Reader", bundle: nil)
        let stubViewController = sb.instantiateViewController(withIdentifier: "StubViewController")
        return stubViewController
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb else {
            return false
        }
        
        if #available(iOS 12, *) {
            if checkUserActivityForBackgroundNFC(userActivity) {
                self.navigationManager?.navigationController.popToRootViewController(animated: false)
//                DispatchQueue.main.async {
//                    self.navigationManager?.rootViewController?.scanButtonPressed(self)
//                }
                return true
            } else {
                return false
            }
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
