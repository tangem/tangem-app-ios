//
//  AppDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import UIKit
import TangemSdk
import Firebase

extension UIApplication {
    
    static func navigationManager() -> NavigationManager {
        return (self.shared.delegate as! AppDelegate).navigationManager!
    }
    
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var navigationManager: NavigationManager?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil)  -> Bool {
        
        initializeNavigationManager()
        
        // Override point for customization after application launch.
        let attrs = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular),
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
        UINavigationBar.appearance().titleTextAttributes = attrs
        UINavigationBar.appearance().barStyle = .blackOpaque
        UINavigationBar.appearance().tintColor = .white
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = TangemSdk.isNFCAvailable ? navigationManager?.navigationController : instantiateStub()
        window.makeKeyAndVisible()
        self.window = window
        let utils = Utils()
        utils.initialize(legacyMode: NfcUtils.isLegacyDevice)
        if !utils.islaunchedBefore {
            let secureStorage = SecureStorageManager()
            secureStorage.set([], forKey: StorageKey.cids)
            utils.setIsLaunchedBefore()
        }
        FirebaseApp.configure()
        
        #if DEBUG
            Firebase.Analytics.setAnalyticsCollectionEnabled(false)
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
        #else
            Firebase.Analytics.setAnalyticsCollectionEnabled(utils.isAnalytycsEnabled)
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(utils.isAnalytycsEnabled)
        #endif
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
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
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
