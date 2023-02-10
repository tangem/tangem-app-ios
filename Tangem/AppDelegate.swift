//
//  AppDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import UIKit
import Firebase
import AppsFlyerLib
import Amplitude

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var loadingView: UIView?

    func addLoadingView() {
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            let view = UIView(frame: window.bounds)
            view.backgroundColor = UIColor(white: 0.0, alpha: 0.6)
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
        AppLog.shared.configure()
        // Override point for customization after application launch.
        UISwitch.appearance().onTintColor = .tangemBlue
        UITableView.appearance().backgroundColor = .clear
        UIScrollView.appearance().keyboardDismissMode = .onDrag

        if #available(iOS 14.0, *) {
            UINavigationBar.appearance().tintColor = UIColor(Colors.Text.primary1)
            UINavigationBar.appearance().titleTextAttributes = [
                .foregroundColor: UIColor(Colors.Text.primary1),
            ]
            // iOS 14 doesn't have extra separators below the list by default.
        } else {
            // To remove only extra separators below the list:
            UITableView.appearance().tableFooterView = UIView()
            UINavigationBar.appearance().tintColor = UIColor(named: "TextPrimary1")
            UINavigationBar.appearance().titleTextAttributes = [
                .foregroundColor: UIColor(named: "TextPrimary1") ?? UIColor.black,
            ]
        }

        if !AppEnvironment.current.isDebug {
            configureFirebase()
            configureAppsFlyer()
            configureAmplitude()
        }

        AppSettings.shared.numberOfLaunches += 1
        S2CTOUMigrator().migrate()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        guard AppEnvironment.current.isProduction else { return }

        AppsFlyerLib.shared().start()
    }
}

private extension AppDelegate {
    func configureFirebase() {
        let plistName = "GoogleService-Info-\(AppEnvironment.current.rawValue.capitalizingFirstLetter())"

        guard let filePath = Bundle.main.path(forResource: plistName, ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: filePath) else {
            assertionFailure("GoogleService-Info.plist not found")
            return
        }

        FirebaseApp.configure(options: options)
    }

    func configureAppsFlyer() {
        guard AppEnvironment.current.isProduction else {
            return
        }

        do {
            let keysManager = try CommonKeysManager()
            AppsFlyerLib.shared().appsFlyerDevKey = keysManager.appsFlyer.appsFlyerDevKey
            AppsFlyerLib.shared().appleAppID = keysManager.appsFlyer.appsFlyerAppID
        } catch {
            assertionFailure("CommonKeysManager not initialized with error: \(error.localizedDescription)")
        }
    }

    func configureAmplitude() {
        Amplitude.instance().trackingSessionEvents = true
        Amplitude.instance().initializeApiKey(try! CommonKeysManager().amplitudeApiKey)
    }
}
