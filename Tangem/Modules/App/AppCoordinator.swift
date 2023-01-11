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
    @Injected(\.walletConnectService) private var walletConnectService: WalletConnectService
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

    private func restart(with options: AppCoordinator.Options = .default) {
        welcomeCoordinator = nil
        authCoordinator = nil
        start(with: options)
    }

    private func setupWelcome(with options: AppCoordinator.Options) {
        let dismissAction = { [weak self] in
            self?.welcomeCoordinator = nil
            self?.start()
        }

        let popToRootAction: ParamsAction<PopToRootOptions> = { [weak self] options in
            self?.closeAllSheetsIfNeeded(animated: true) {
                self?.welcomeCoordinator = nil
                self?.start(with: .init(connectionOptions: nil, newScan: options.newScan))
            }
        }

        let shouldScan = options.newScan ?? false

        let coordinator = WelcomeCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: .init(shouldScan: shouldScan))
        self.welcomeCoordinator = coordinator
    }

    private func setupAuth(with options: AppCoordinator.Options) {
        let dismissAction = { [weak self] in
            self?.authCoordinator = nil
            self?.start()
        }

        let popToRootAction: ParamsAction<PopToRootOptions> = { [weak self] options in
            self?.closeAllSheetsIfNeeded(animated: true) {
                self?.authCoordinator = nil
                self?.start(with: .init(connectionOptions: nil, newScan: options.newScan))
            }
        }

        let unlockOnStart = options.newScan ?? true

        let coordinator = AuthCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)
        coordinator.start(with: .init(unlockOnStart: unlockOnStart))
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
                if case .locked(let reason) = event {
                    self?.handleLock(reason: reason)
                }
            }
            .store(in: &bag)
    }

    private func handleLock(reason: UserWalletRepositoryLockReason) {
        let animated: Bool
        let newScan: Bool

        switch reason {
        case .loggedOut:
            animated = false
            newScan = AppSettings.shared.saveUserWallets
        case .nothingToDisplay:
            animated = true
            newScan = false
        }

        let options = AppCoordinator.Options(connectionOptions: nil, newScan: newScan)

        closeAllSheetsIfNeeded(animated: animated) {
            if animated {
                self.restart(with: options)
            } else {
                UIApplication.performWithoutAnimations {
                    self.restart(with: options)
                }
            }
        }
    }

    private func closeAllSheetsIfNeeded(animated: Bool, completion: @escaping () -> Void = { }) {
        guard let topViewController = UIApplication.topViewController,
              topViewController.presentingViewController != nil else {
            DispatchQueue.main.async {
                completion()
            }
            return
        }

        topViewController.dismiss(animated: animated) {
            self.closeAllSheetsIfNeeded(animated: animated, completion: completion)
        }
    }
}

extension AppCoordinator {
    struct Options {
        let connectionOptions: UIScene.ConnectionOptions?
        let newScan: Bool?

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
        if walletConnectService.handle(url: url) {
            return
        }

        guard url.lastPathComponent == "wc" else {
            return
        }

        if case .welcome = StartupProcessor().getStartupOption() {
            let controller = AlertBuilder.makeOkGotItAlertController(message: Localization.walletConnectNeedToScanCard)
            AppPresenter.shared.show(controller, delay: 0.5)
        }
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
