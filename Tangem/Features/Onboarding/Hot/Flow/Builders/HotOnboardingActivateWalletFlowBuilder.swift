//
//  HotOnboardingActivateWalletFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization

final class HotOnboardingActivateWalletFlowBuilder: HotOnboardingFlowBuilder {
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor

    private var isBackupNeeded: Bool {
        !userWalletModel.config.hasFeature(.mnemonicBackup)
    }

    private var isAccessCodeNeeded: Bool {
        userWalletModel.config.hasFeature(.userWalletAccessCode)
    }

    private let userWalletModel: UserWalletModel
    private weak var coordinator: HotOnboardingFlowRoutable?

    init(userWalletModel: UserWalletModel, coordinator: HotOnboardingFlowRoutable) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
        super.init()
    }

    override func setupFlow() {
        if isBackupNeeded {
            setupSeedPhraseBackupFlow()
        }

        if isAccessCodeNeeded {
            setupAccessCodeFlow()
        }

        let factory = PushNotificationsHelpersFactory()
        let availabilityProvider = factory.makeAvailabilityProviderForAfterLogin(using: pushNotificationsInteractor)

        if availabilityProvider.isAvailable {
            let permissionManager = factory.makePermissionManagerForAfterLogin(using: pushNotificationsInteractor)
            let pushNotificationsStep = HotOnboardingPushNotificationsStep(
                permissionManager: permissionManager,
                delegate: self
            )
            pushNotificationsStep.configureNavBar(title: Localization.onboardingTitleNotifications)
            append(step: pushNotificationsStep)
        }

        let doneStep = HotOnboardingSuccessStep(
            type: .walletReady,
            onAppear: weakify(self, forFunction: HotOnboardingActivateWalletFlowBuilder.openConfetti),
            onComplete: weakify(self, forFunction: HotOnboardingActivateWalletFlowBuilder.closeOnboarding)
        )
        doneStep.configureNavBar(title: Localization.commonDone)
        append(step: doneStep)

        setupProgress()
    }
}

// MARK: - Flows

private extension HotOnboardingActivateWalletFlowBuilder {
    func setupSeedPhraseBackupFlow() {
        let seedPhraseIntroStep = HotOnboardingSeedPhraseIntroStep(delegate: self)
            .configureNavBar(
                title: Localization.commonBackup,
                leadingAction: .close(handler: { [weak self] in
                    self?.closeOnboarding()
                })
            )
        append(step: seedPhraseIntroStep)

        let seedPhraseResolver = CommonHotOnboardingSeedPhraseResolver(userWalletModel: userWalletModel)

        let seedPhraseRecoveryStep = HotOnboardingSeedPhraseRecoveryStep(
            seedPhraseResolver: seedPhraseResolver,
            delegate: self
        )
        .configureNavBar(
            title: Localization.commonBackup,
            leadingAction: navBarBackAction
        )
        append(step: seedPhraseRecoveryStep)

        let seedPhraseValidationStep = HotOnboardingSeedPhraseValidationStep(
            seedPhraseResolver: seedPhraseResolver,
            onCreateWallet: weakify(self, forFunction: HotOnboardingActivateWalletFlowBuilder.openNext)
        )
        seedPhraseValidationStep.configureNavBar(
            title: Localization.commonBackup,
            leadingAction: navBarBackAction
        )
        append(step: seedPhraseValidationStep)

        let doneStep = HotOnboardingSuccessStep(
            type: .seedPhaseBackupContinue,
            onAppear: {},
            onComplete: weakify(self, forFunction: HotOnboardingActivateWalletFlowBuilder.openNext)
        )
        doneStep.configureNavBar(title: Localization.commonBackup)
        append(step: doneStep)
    }

    func setupAccessCodeFlow() {
        let accessCodeStep = HotOnboardingAccessCodeStep(context: nil, delegate: self)
        accessCodeStep.configureNavBar(title: Localization.accessCodeNavtitle)
        append(step: accessCodeStep)
    }
}

// MARK: - Navigation

private extension HotOnboardingActivateWalletFlowBuilder {
    func openNext() {
        next()
    }

    func openMain() {
        coordinator?.openMain(userWalletModel: userWalletModel)
    }

    func openConfetti() {
        coordinator?.openConfetti()
    }

    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}

// MARK: - HotOnboardingSeedPhraseIntroDelegate

extension HotOnboardingActivateWalletFlowBuilder: HotOnboardingSeedPhraseIntroDelegate {
    func seedPhraseIntroContinue() {
        openNext()
    }
}

// MARK: - HotOnboardingSeedPhraseRecoveryDelegate

extension HotOnboardingActivateWalletFlowBuilder: HotOnboardingSeedPhraseRecoveryDelegate {
    func seedPhraseRecoveryContinue() {
        openNext()
    }
}

// MARK: - HotOnboardingAccessCodeDelegate

extension HotOnboardingActivateWalletFlowBuilder: HotOnboardingAccessCodeDelegate {
    func getUserWalletModel() -> UserWalletModel? {
        userWalletModel
    }

    func didCompleteAccessCode() {
        openNext()
    }
}

// MARK: - PushNotificationsPermissionRequestDelegate

extension HotOnboardingActivateWalletFlowBuilder: PushNotificationsPermissionRequestDelegate {
    func didFinishPushNotificationOnboarding() {
        next()
    }
}
