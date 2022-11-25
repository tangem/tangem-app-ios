//
//  AppCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine

class AppCoordinator: NSObject, CoordinatorObject {
    var dismissAction: () -> Void = {}
    var popToRootAction: (PopToRootOptions) -> Void = { _ in }

    // MARK: - Injected
    @Injected(\.walletConnectServiceProvider) private var walletConnectServiceProvider: WalletConnectServiceProviding
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Child coordinators
    @Published var welcomeCoordinator: WelcomeCoordinator?
    @Published var uncompletedBackupCoordinator: UncompletedBackupCoordinator?
    @Published var authCoordinator: AuthCoordinator?

    // MARK: - Private
    private let servicesManager: ServicesManager = .init()
    private var bag: Set<AnyCancellable> = []

    override init() {
        super.init()
        servicesManager.initialize()
        bind()
    }

    func start(with options: AppCoordinator.Options = .default) {
        let startupProcessor = StartupProcessor()
        let startupOption = startupProcessor.getStartupOption()

        switch startupOption {
        case .welcome:
            setupWelcome(with: options)
        case .auth:
            setupAuth(with: options)
        case .uncompletedBackup:
            setupUncompletedBackup()
        }

        if let options = options.connectionOptions, startupOption != .uncompletedBackup {
            handle(contexts: options.urlContexts)
            handle(activities: options.userActivities)
        }
    }

    private func setupWelcome(with options: AppCoordinator.Options) {
        let dismissAction = { [weak self] in
            self?.welcomeCoordinator = nil
            self?.start()
        }

        let popToRootAction: ParamsAction<PopToRootOptions> = { [weak self] options in
            self?.welcomeCoordinator = nil
            self?.start(with: .init(connectionOptions: nil, newScan: options.newScan))
        }

        let coordinator = WelcomeCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: .init(shouldScan: options.newScan))
        self.welcomeCoordinator = coordinator
    }

    private func setupAuth(with options: AppCoordinator.Options) {
        let dismissAction = { [weak self] in
            self?.authCoordinator = nil
            self?.start()
        }

        let popToRootAction: ParamsAction<PopToRootOptions> = { [weak self] options in
            self?.authCoordinator = nil
            self?.start(with: .init(connectionOptions: nil, newScan: options.newScan))
        }

        let coordinator = AuthCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start()
        self.authCoordinator = coordinator
    }

    private func setupUncompletedBackup() {
        let dismissAction = { [weak self] in
            self?.uncompletedBackupCoordinator = nil
            self?.start()
        }

        let coordinator = UncompletedBackupCoordinator(dismissAction: dismissAction)
        coordinator.start()
        self.uncompletedBackupCoordinator = coordinator
    }

    private func bind() {
        userWalletRepository
            .eventProvider
            .sink { [weak self] event in
                if case .locked = event {
                    self?.handleLock()
                }
            }
            .store(in: &bag)
    }

    private func handleLock() {
        welcomeCoordinator = nil
        authCoordinator = nil
        start()
    }
}

extension AppCoordinator {
    struct Options {
        let connectionOptions: UIScene.ConnectionOptions?
        let newScan: Bool

        static let `default`: Options = .init(connectionOptions: nil, newScan: false)
    }
}

// MARK: - UIWindowSceneDelegate
extension AppCoordinator: UIWindowSceneDelegate {
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handle(activities: [userActivity])
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
