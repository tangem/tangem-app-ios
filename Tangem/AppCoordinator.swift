//
//  AppCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

class AppCoordinator: NSObject, CoordinatorObject {
    var dismissAction: () -> Void = {}
    var popToRootAction: (PopToRootOptions) -> Void = { _ in }

    // MARK: - Injected
    @Injected(\.walletConnectServiceProvider) private var walletConnectServiceProvider: WalletConnectServiceProviding

    // MARK: - Child coordinators
    @Published var welcomeCoordinator: WelcomeCoordinator = .init()

    // MARK: - Private
    private let servicesManager: ServicesManager = .init()
    private var deferredIntents: [NSUserActivity] = []
    private var deferredIntentWork: DispatchWorkItem?

    override init() {
        servicesManager.initialize()
    }

    func start(with options: AppCoordinator.Options = .default) {
        welcomeCoordinator.dismissAction = { [weak self] in self?.popToRoot() }
        welcomeCoordinator.start(with: .init(shouldScan: false))

        if let options = options.connectionOptions {
            handle(contexts: options.urlContexts)
            handle(activities: options.userActivities)
        }
    }

    func popToRoot() {
        welcomeCoordinator = .init()
        welcomeCoordinator.start(with: .init(shouldScan: false))
    }
}

extension AppCoordinator {
    struct Options {
        let connectionOptions: UIScene.ConnectionOptions?

        static let `default`: Options = .init(connectionOptions: nil)
    }
}

// MARK: - UIWindowSceneDelegate
extension AppCoordinator: UIWindowSceneDelegate {
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
                    // [REDACTED_TODO_COMMENT]
                    self?.welcomeCoordinator = .init()
                    self?.welcomeCoordinator.start(with: .init(shouldScan: true))
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
        if let wcService = walletConnectServiceProvider.service {
            wcService.handle(url: url)
            return
        }

        guard url.lastPathComponent == "wc" else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            UIApplication.modalFromTop(
                AlertBuilder.makeOkGotItAlertController(message: "wallet_connect_need_to_scan_card".localized)
            )
        })
    }
}

// MARK: - URLHandler
extension AppCoordinator: URLHandler {
    @discardableResult func handle(url: String) -> Bool {
        guard url.starts(with: "https://app.tangem.com")
            || url.starts(with: Constants.tangemDomain + "/ndef") else { return false }

        return true
    }

    @discardableResult func handle(url: URL) -> Bool {
        handle(url: url.absoluteString)
    }
}
