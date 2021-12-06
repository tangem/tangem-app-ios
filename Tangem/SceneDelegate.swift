//
//  SceneDelegate.swift
//  Tangem
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
    
    private var deferredIntents: [NSUserActivity] = []
    private var deferredIntentWork: DispatchWorkItem?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        assembly.services.walletConnectService.restore()
        // Create the SwiftUI view that provides the window contents.
        assembly.services.urlHandlers.append(self)
     
//        let vm = assembly.makeReadViewModel()
//        let contentView = ContentView() { ReadView(viewModel: vm) }
//            .environmentObject(assembly)
//            .environmentObject(assembly.services.navigationCoordinator)
            
        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = prepareRootController()
            self.window = window
            window.makeKeyAndVisible()
        }
        handleActivity(connectionOptions.userActivities)
        handleURL(contexts: connectionOptions.urlContexts)
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handleActivity([userActivity])
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        
        deferredIntentWork = DispatchWorkItem { [weak self] in
            self?.deferredIntents.forEach {
                switch $0.activityType {
                case String(describing: ScanTangemCardIntent.self):
                    //todo: test
                    self?.assembly.getLetsStartOnboardingViewModel()?.scanCard()
                default:
                    break
                }
            }
            self?.deferredIntents.removeAll()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: deferredIntentWork!)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        deferredIntentWork?.cancel()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        handleURL(contexts: URLContexts)
    }
    
    private func handleActivity(_ userActivity: Set<NSUserActivity>) {
        userActivity.forEach {
            switch $0.activityType {
            case NSUserActivityTypeBrowsingWeb:
                guard let url = $0.webpageURL else { return }
                
                handleUrl(url)
            case String(describing: ScanTangemCardIntent.self):
                assembly.services.navigationCoordinator.popToRoot()
                deferredIntents.append($0)
            default: return
            }
        }
    }
    
    private func handleURL(contexts: Set<UIOpenURLContext>) {
        if let url = contexts.first?.url {
            handleUrl(url)
        }
    }
    
    private func handleUrl(_ url: URL) {
        self.assembly.services.urlHandlers.forEach {
            $0.handle(url: url)
        }
    }
    
    private func prepareRootController() -> UIViewController {
        let vm = assembly.getLaunchOnboardingViewModel()
        let contentView = ContentView() {
            OnboardingBaseView(viewModel: vm)
        }
            .environmentObject(assembly)
            .environmentObject(assembly.services.navigationCoordinator)
        return UIHostingController(rootView: contentView)
    }
}

extension SceneDelegate: URLHandler {
    func handle(url: String) -> Bool {
        guard url.starts(with: "https://app.tangem.com")
                || url.starts(with: Constants.tangemDomain + "/ndef")
                || url.starts(with: Constants.tangemDomain + "/wc") else { return false }
        
        assembly.services.navigationCoordinator.popToRoot()
        return true
    }
    
    func handle(url: URL) -> Bool {
        handle(url: url.absoluteString)
    }
}
