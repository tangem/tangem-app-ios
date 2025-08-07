//
//  HotOnboardingImportWalletFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import struct TangemSdk.Mnemonic
import TangemFoundation
import TangemHotSdk

final class HotOnboardingImportWalletFlowBuilder: HotOnboardingFlowBuilder {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor

    private var userWalletModel: UserWalletModel?

    private weak var coordinator: HotOnboardingFlowRoutable?

    init(coordinator: HotOnboardingFlowRoutable) {
        self.coordinator = coordinator
        super.init()
    }

    override func setupFlow() {
        let importWalletStep = HotOnboardingImportWalletStep(delegate: self)
            .configureNavBar(
                title: Localization.walletImportTitle,
                leadingAction: .back(handler: { [weak self] in
                    self?.closeOnboarding()
                })
            )
        append(step: importWalletStep)

        let importCompletedStep = HotOnboardingSuccessStep(
            type: .walletImported,
            onAppear: {},
            onComplete: weakify(self, forFunction: HotOnboardingImportWalletFlowBuilder.openNext)
        )
        importCompletedStep.configureNavBar(title: Localization.walletImportTitle)
        append(step: importCompletedStep)

        let createAccessCodeStep = HotOnboardingCreateAccessCodeStep(delegate: self)
            .configureNavBar(title: Localization.accessCodeNavtitle)
        append(step: createAccessCodeStep)

        let factory = PushNotificationsHelpersFactory()
        let availabilityProvider = factory.makeAvailabilityProviderForWalletOnboarding(using: pushNotificationsInteractor)

        if availabilityProvider.isAvailable {
            let permissionManager = factory.makePermissionManagerForWalletOnboarding(using: pushNotificationsInteractor)
            let pushNotificationsStep = HotOnboardingPushNotificationsStep(
                permissionManager: permissionManager,
                delegate: self
            )
            pushNotificationsStep.configureNavBar(title: Localization.onboardingTitleNotifications)
            append(step: pushNotificationsStep)
        }

        let doneStep = HotOnboardingSuccessStep(
            type: .walletReady,
            onAppear: weakify(self, forFunction: HotOnboardingImportWalletFlowBuilder.openConfetti),
            onComplete: weakify(self, forFunction: HotOnboardingImportWalletFlowBuilder.openMain)
        )
        doneStep.configureNavBar(title: Localization.commonDone)
        append(step: doneStep)

        setupProgress()
    }
}

// MARK: - Navigation

private extension HotOnboardingImportWalletFlowBuilder {
    func openNext() {
        next()
    }

    func openMain() {
        guard let userWalletModel else {
            return
        }
        coordinator?.openMain(userWalletModel: userWalletModel)
    }

    func openConfetti() {
        coordinator?.openConfetti()
    }

    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }

    @MainActor
    private func handleWalletCreated(_ newUserWalletModel: UserWalletModel) throws {
        userWalletModel = newUserWalletModel

        next()
    }
}

// MARK: - SeedPhraseImportDelegate

extension HotOnboardingImportWalletFlowBuilder: SeedPhraseImportDelegate {
    func importSeedPhrase(mnemonic: Mnemonic, passphrase: String) {
        runTask(in: self) { @MainActor builder in
            do {
                let initializer = MobileWalletInitializer()

                let walletInfo = try await initializer.initializeWallet(mnemonic: mnemonic, passphrase: passphrase)

                guard let newUserWalletModel = CommonUserWalletModelFactory().makeModel(
                    walletInfo: .mobileWallet(walletInfo),
                    keys: .mobileWallet(keys: walletInfo.keys),
                ) else {
                    throw UserWalletRepositoryError.cantUnlockWallet
                }

                try builder.userWalletRepository.add(userWalletModel: newUserWalletModel)

                try builder.handleWalletCreated(newUserWalletModel)
            } catch {
                AppLogger.error("Failed to create wallet", error: error)
                throw error
            }
        }
    }
}

// MARK: - HotOnboardingAccessCodeDelegate

extension HotOnboardingImportWalletFlowBuilder: HotOnboardingAccessCodeCreateDelegate {
    func isRequestBiometricsNeeded() -> Bool {
        true
    }

    func isAccessCodeCanSkipped() -> Bool {
        true
    }

    func accessCodeComplete(accessCode: String) {
        guard let userWalletModel else {
            return
        }
        // [REDACTED_TODO_COMMENT]
        next()
    }

    func accessCodeSkipped() {
        guard let userWalletModel else {
            return
        }
        let userWalletIdString = userWalletModel.userWalletId.stringValue
        AppSettings.shared.userWalletIdsWithSkippedAccessCode.appendIfNotContains(userWalletIdString)
        next()
    }
}

// MARK: - PushNotificationsPermissionRequestDelegate

extension HotOnboardingImportWalletFlowBuilder: PushNotificationsPermissionRequestDelegate {
    func didFinishPushNotificationOnboarding() {
        next()
    }
}
