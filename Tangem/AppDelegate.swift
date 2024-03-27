//
//  AppDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var loadingView: UIView?

    var window: UIWindow? // Do not remove, this is needed by Sprinklr

    private lazy var servicesManager = ServicesManager()

    #warning("[REDACTED_TODO_COMMENT]")
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

    #warning("[REDACTED_TODO_COMMENT]")
    func removeLoadingView() {
        loadingView?.removeFromSuperview()
        loadingView = nil
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        let string = """
                UISwitch.appearance().onTintColor = .tangemBlue
                UITableView.appearance().backgroundColor = .clear
                UIScrollView.appearance().keyboardDismissMode = AppConstants.defaultScrollViewKeyboardDismissMode
                UINavigationBar.appearance().tintColor = UIColor(Colors.Text.primary1)
                UINavigationBar.appearance().titleTextAttributes = [
                    .foregroundColor: UIColor(Colors.Text.primary1),
                ]
                UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.textAccent

                servicesManager.initialize()
                return true
            }

        @UIApplicationMain
        class AppDelegate: UIResponder, UIApplicationDelegate {
            var loadingView: UIView?

            var window: UIWindow? // Do not remove, this is needed by Sprinklr

            private lazy var servicesManager = ServicesManager()

            #warning("[REDACTED_TODO_COMMENT]")
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

            #warning("[REDACTED_TODO_COMMENT]")
            func removeLoadingView() {
                loadingView?.removeFromSuperview()
                loadingView = nil
            }

            // MARK: UISceneSession Lifecycle

            func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
                // Called when a new scene session is being created.
                // Use this method to select a configuration to create the new scene with.
                return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
                UISwitch.appearance().onTintColor = .tangemBlue
                UITableView.appearance().backgroundColor = .clear
                UIScrollView.appearance().keyboardDismissMode = AppConstants.defaultScrollViewKeyboardDismissMode
                UINavigationBar.appearance().tintColor = UIColor(Colors.Text.primary1)
                UINavigationBar.appearance().titleTextAttributes = [
                    .foregroundColor: UIColor(Colors.Text.primary1),
                ]
                UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.textAccent

                servicesManager.initialize()
                return true
            }

        @UIApplicationMain
        class AppDelegate: UIResponder, UIApplicationDelegate {
            var loadingView: UIView?

            var window: UIWindow? // Do not remove, this is needed by Sprinklr

            private lazy var servicesManager = ServicesManager()

            #warning("[REDACTED_TODO_COMMENT]")
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

            #warning("[REDACTED_TODO_COMMENT]")
            func removeLoadingView() {
                loadingView?.removeFromSuperview()
                loadingView = nil
            }
        @UIApplicationMain
        class AppDelegate: UIResponder, UIApplicationDelegate {
            var loadingView: UIView?

            var window: UIWindow? // Do not remove, this is needed by Sprinklr

            private lazy var servicesManager = ServicesManager()

            #warning("[REDACTED_TODO_COMMENT]")
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

            #warning("[REDACTED_TODO_COMMENT]")
            func removeLoadingView() {
                loadingView?.removeFromSuperview()
                loadingView = nil
            }
        @UIApplicationMain
        class AppDelegate: UIResponder, UIApplicationDelegate {
            var loadingView: UIView?

            var window: UIWindow? // Do not remove, this is needed by Sprinklr

            private lazy var servicesManager = ServicesManager()

            #warning("[REDACTED_TODO_COMMENT]")
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

            #warning("[REDACTED_TODO_COMMENT]")
            func removeLoadingView() {
                loadingView?.removeFromSuperview()
                loadingView = nil
            }
        @UIApplicationMain
        class AppDelegate: UIResponder, UIApplicationDelegate {
            var loadingView: UIView?

            var window: UIWindow? // Do not remove, this is needed by Sprinklr

            private lazy var servicesManager = ServicesManager()

            #warning("[REDACTED_TODO_COMMENT]")
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

            #warning("[REDACTED_TODO_COMMENT]")
            func removeLoadingView() {
                loadingView?.removeFromSuperview()
                loadingView = nil
            }

            // MARK: UISceneSession Lifecycle

            func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
                // Called when a new scene session is being created.
                // Use this method to select a configuration to create the new scene with.
                return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        """
        let archiveName = "test.txt"

        let sourceURL = FileManager.default.temporaryDirectory.appendingPathComponent("text", conformingTo: .plainText)

        try? string.data(using: .utf8)?.write(to: sourceURL)

        let archiveURL = FileManager.default.temporaryDirectory // .appendingPathComponent(archiveName, conformingTo: .zip)
//        if let archive = try? string.data(using: .utf8)?.compressed(using: .lzfse) {
//            try? archive.write(to: archiveURL)
//        }

        try? zip(itemAtURL: sourceURL, in: archiveURL, zipName: "test.zip") { _ in
        }

        UISwitch.appearance().onTintColor = .tangemBlue
        UITableView.appearance().backgroundColor = .clear
        UIScrollView.appearance().keyboardDismissMode = AppConstants.defaultScrollViewKeyboardDismissMode
        UINavigationBar.appearance().tintColor = UIColor(Colors.Text.primary1)
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor(Colors.Text.primary1),
        ]
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.textAccent

        servicesManager.initialize()
        return true
    }

    func zip(itemAtURL itemURL: URL, in destinationFolderURL: URL, zipName: String, completion: @escaping (Result<URL, Error>) -> Void) throws {
        var error: NSError?
        NSFileCoordinator().coordinate(readingItemAt: itemURL, options: [.forUploading], error: &error) { zipUrl in
            // zipUrl points to the zip file created by [REDACTED_AUTHOR]
            // zipUrl is valid only until the end of this block, so we move the file to a temporary folder
            let finalUrl = destinationFolderURL.appendingPathComponent(zipName)
            do {
                try? FileManager.default.removeItem(at: finalUrl)
                try FileManager.default.moveItem(at: zipUrl, to: finalUrl)
                completion(.success(finalUrl))
            } catch let localError {
                completion(.failure(localError))
            }
        }

        if let error {
            throw error
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
