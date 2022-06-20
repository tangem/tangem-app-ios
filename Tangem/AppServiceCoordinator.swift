//
//  AppServiceCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

class AppServiceCoordinator: NSObject, CoordinatorObject {
    //MARK: - Injected
    @Injected(\.walletConnectServiceProvider) private var walletConnectServiceProvider: WalletConnectServiceProviding
    
    //MARK: - Child coordinators
    @Published var appCoordinator: AppCoordinator = .init()
    
    var dismissAction: () -> Void = {}
    
    //MARK: - Private
    private let servicesManager: ServicesManager = .init()
    private var deferredIntents: [NSUserActivity] = []
    private var deferredIntentWork: DispatchWorkItem?
    
    override init() {
        servicesManager.initialize()
    }
    
    func start(with options: UIScene.ConnectionOptions? = nil) {
        appCoordinator.dismissAction = { [weak self] in self?.popToRoot() }
        appCoordinator.start()
        
        if let options = options {
            handle(contexts: options.urlContexts)
            handle(activities: options.userActivities)
        }
    }
    
    func popToRoot() {
        appCoordinator = .init()
        appCoordinator.start()
    }
}


//MARK: - UIWindowSceneDelegate
extension AppServiceCoordinator: UIWindowSceneDelegate {
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
                    self?.appCoordinator = .init()
                    self?.appCoordinator.start()
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
                popToRoot()
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
}

//MARK: - URLHandler
extension AppServiceCoordinator: URLHandler {
    @discardableResult func handle(url: String) -> Bool {
        guard url.starts(with: "https://app.tangem.com")
                || url.starts(with: Constants.tangemDomain + "/ndef")
                || url.starts(with: Constants.tangemDomain + "/wc") else { return false }
        
        popToRoot()
        return true
    }
    
    @discardableResult func handle(url: URL) -> Bool {
        handle(url: url.absoluteString)
    }
}
