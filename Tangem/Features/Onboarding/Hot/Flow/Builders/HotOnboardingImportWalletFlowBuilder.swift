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

final class HotOnboardingImportWalletFlowBuilder: HotOnboardingFlowBuilder {
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
        flow.append(importWalletStep)

        let importCompletedStep = HotOnboardingSuccessStep(
            type: .walletImported,
            onAppear: {},
            onComplete: weakify(self, forFunction: HotOnboardingImportWalletFlowBuilder.openNext)
        )
        importCompletedStep.configureNavBar(title: Localization.walletImportTitle)
        flow.append(importCompletedStep)

        let createAccessCodeStep = HotOnboardingCreateAccessCodeStep(coordinator: self, delegate: self)
            .configureNavBar(title: Localization.accessCodeNavtitle)
        flow.append(createAccessCodeStep)

        let factory = PushNotificationsHelpersFactory()
        let availabilityProvider = factory.makeAvailabilityProviderForWalletOnboarding(using: pushNotificationsInteractor)

        if availabilityProvider.isAvailable {
            let permissionManager = factory.makePermissionManagerForWalletOnboarding(using: pushNotificationsInteractor)
            let pushNotificationsStep = HotOnboardingPushNotificationsStep(
                permissionManager: permissionManager,
                delegate: self
            )
            pushNotificationsStep.configureNavBar(title: Localization.onboardingTitleNotifications)
            flow.append(pushNotificationsStep)
        }

        let doneStep = HotOnboardingSuccessStep(
            type: .walletReady,
            onAppear: weakify(self, forFunction: HotOnboardingImportWalletFlowBuilder.openConfetti),
            onComplete: weakify(self, forFunction: HotOnboardingImportWalletFlowBuilder.openMain)
        )
        doneStep.configureNavBar(title: Localization.commonDone)
        flow.append(doneStep)

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
}

// MARK: - SeedPhraseImportDelegate

extension HotOnboardingImportWalletFlowBuilder: SeedPhraseImportDelegate {
    func importSeedPhrase(mnemonic: Mnemonic, passphrase: String?) {
        // [REDACTED_TODO_COMMENT]
        // self.userWalletModel = userWalletModel
        userWalletModel = UserWalletModelMock()
        next()
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
        // [REDACTED_TODO_COMMENT]
        next()
    }
}

// MARK: - HotOnboardingAccessCodeCreateRoutable

extension HotOnboardingImportWalletFlowBuilder: HotOnboardingAccessCodeCreateRoutable {
    func openAccesCodeSkipAlert(onSkip: @escaping () -> Void) {
        coordinator?.openAccesCodeSkipAlert(onSkip: onSkip)
    }
}

// MARK: - PushNotificationsPermissionRequestDelegate

extension HotOnboardingImportWalletFlowBuilder: PushNotificationsPermissionRequestDelegate {
    func didFinishPushNotificationOnboarding() {
        next()
    }
}
