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
    @Injected(\.assemblyProvider) private var assemblyProvider: AssemblyProviding
    @Injected(\.navigationCoordinatorProvider) private var navigationCoordinatorProvider: NavigationCoordinatorProviding
    @Injected(\.walletConnectServiceProvider) private var walletConnectServiceProvider: WalletConnectServiceProviding
    
    var window: UIWindow?
    
    private var deferredIntents: [NSUserActivity] = []
    private var deferredIntentWork: DispatchWorkItem?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        walletConnectServiceProvider.service.restore()
     
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
        handle(activities: connectionOptions.userActivities)
        handle(contexts: connectionOptions.urlContexts)
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handle(activities: [userActivity])
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        
        deferredIntentWork = DispatchWorkItem { [weak self] in
            self?.deferredIntents.forEach {
                switch $0.activityType {
                case String(describing: ScanTangemCardIntent.self):
                    //todo: test
                    self?.assemblyProvider.assembly.getLetsStartOnboardingViewModel()?.scanCard()
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
        handle(contexts: URLContexts)
    }
    
    private func handle(activities: Set<NSUserActivity>) {
        activities.forEach {
            switch $0.activityType {
            case NSUserActivityTypeBrowsingWeb:
                guard let url = $0.webpageURL else { return }
                
                process(url)
            case String(describing: ScanTangemCardIntent.self):
                navigationCoordinatorProvider.coordinator.popToRoot()
                deferredIntents.append($0)
            default: return
            }
        }
    }
    
    private func handle(contexts: Set<UIOpenURLContext>) {
        if let url = contexts.first?.url {
            process(url)
        }
    }
    
    private func process(_ url: URL) {
        handle(url: url)
        walletConnectServiceProvider.service.handle(url: url)
    }
    
    private func prepareRootController() -> UIViewController {
        let vm = assemblyProvider.assembly.getLaunchOnboardingViewModel()
        let contentView = ContentView() {
            OnboardingBaseView(viewModel: vm)
        }
            .environmentObject(assemblyProvider.assembly)
            .environmentObject(navigationCoordinatorProvider.coordinator)
        return UIHostingController(rootView: contentView)
    }
}

extension SceneDelegate: URLHandler {
    @discardableResult func handle(url: String) -> Bool {
        guard url.starts(with: "https://app.tangem.com")
                || url.starts(with: Constants.tangemDomain + "/ndef")
                || url.starts(with: Constants.tangemDomain + "/wc") else { return false }
        
        navigationCoordinatorProvider.coordinator.popToRoot()
        return true
    }
    
    @discardableResult func handle(url: URL) -> Bool {
        handle(url: url.absoluteString)
    }
}
