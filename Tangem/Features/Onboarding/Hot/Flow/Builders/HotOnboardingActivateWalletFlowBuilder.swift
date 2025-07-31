//
//  HotOnboardingActivateWalletFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

final class HotOnboardingActivateWalletFlowBuilder: HotOnboardingFlowBuilder {
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor

    private let statusUtil: HotStatusUtil
    private let userWalletModel: UserWalletModel
    private weak var coordinator: HotOnboardingFlowRoutable?

    init(userWalletModel: UserWalletModel, coordinator: HotOnboardingFlowRoutable) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
        statusUtil = HotStatusUtil(userWalletModel: userWalletModel)
        super.init()
    }

    override func setupFlow() {
        if statusUtil.isBackupNeeded {
            setupBackupFlow()
        }

        if statusUtil.isAccessCodeNeeded {
            setupAccessCodeFlow()
        }

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
            onAppear: weakify(self, forFunction: HotOnboardingActivateWalletFlowBuilder.openConfetti),
            onComplete: weakify(self, forFunction: HotOnboardingActivateWalletFlowBuilder.closeOnboarding)
        )
        doneStep.configureNavBar(title: Localization.commonDone)
        flow.append(doneStep)

        setupProgress()
    }
}

// MARK: - Flows

private extension HotOnboardingActivateWalletFlowBuilder {
    func setupBackupFlow() {
        let seedPhraseIntroStep = HotOnboardingSeedPhraseIntroStep(delegate: self)
            .configureNavBar(
                title: Localization.commonBackup,
                leadingAction: .close(handler: { [weak self] in
                    self?.closeOnboarding()
                })
            )
        flow.append(seedPhraseIntroStep)

        let seedPhraseResolver = CommonHotOnboardingSeedPhraseResolver(userWalletModel: userWalletModel)

        let seedPhraseRecoveryStep = HotOnboardingSeedPhraseRecoveryStep(
            seedPhraseResolver: seedPhraseResolver,
            delegate: self
        )
        .configureNavBar(
            title: Localization.commonBackup,
            leadingAction: navBarBackAction
        )
        flow.append(seedPhraseRecoveryStep)

        let seedPhraseValidationStep = HotOnboardingSeedPhraseValidationStep(
            seedPhraseResolver: seedPhraseResolver,
            onCreateWallet: weakify(self, forFunction: HotOnboardingActivateWalletFlowBuilder.openNext)
        )
        seedPhraseValidationStep.configureNavBar(
            title: Localization.commonBackup,
            leadingAction: navBarBackAction
        )
        flow.append(seedPhraseValidationStep)

        let doneStep = HotOnboardingSuccessStep(
            type: .seedPhaseBackupContinue,
            onAppear: {},
            onComplete: weakify(self, forFunction: HotOnboardingActivateWalletFlowBuilder.openNext)
        )
        doneStep.configureNavBar(title: Localization.commonBackup)
        flow.append(doneStep)
    }

    func setupAccessCodeFlow() {
        let createAccessCodeStep = HotOnboardingCreateAccessCodeStep(coordinator: self, delegate: self)
        createAccessCodeStep.configureNavBar(title: Localization.accessCodeNavtitle)
        flow.append(createAccessCodeStep)
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

extension HotOnboardingActivateWalletFlowBuilder: HotOnboardingAccessCodeCreateDelegate {
    func isRequestBiometricsNeeded() -> Bool {
        true
    }

    func isAccessCodeCanSkipped() -> Bool {
        true
    }

    func accessCodeComplete(accessCode: String) {
        // [REDACTED_TODO_COMMENT]
        openNext()
    }

    func accessCodeSkipped() {
        // [REDACTED_TODO_COMMENT]
        openNext()
    }
}

// MARK: - HotOnboardingAccessCodeCreateRoutable

extension HotOnboardingActivateWalletFlowBuilder: HotOnboardingAccessCodeCreateRoutable {
    func openAccesCodeSkipAlert(onSkip: @escaping () -> Void) {
        coordinator?.openAccesCodeSkipAlert(onSkip: onSkip)
    }
}

// MARK: - PushNotificationsPermissionRequestDelegate

extension HotOnboardingActivateWalletFlowBuilder: PushNotificationsPermissionRequestDelegate {
    func didFinishPushNotificationOnboarding() {
        next()
    }
}
