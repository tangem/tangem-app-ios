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
    override var hasProgressBar: Bool { true }

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
            var pushNotificationsStep = HotOnboardingPushNotificationsStep(
                permissionManager: permissionManager,
                delegate: self
            )
            let pushNotificationsNode = flow.append(pushNotificationsStep)
            pushNotificationsStep.configureNavigation(title: Localization.onboardingTitleNotifications)
            pushNotificationsStep.setupProgress { [weak self] in
                self?.progressValue(node: pushNotificationsNode)
            }
        }

        var doneStep = HotOnboardingSuccessStep(
            type: .walletReady,
            onAppear: weakify(self, forFunction: HotOnboardingActivateWalletFlowBuilder.openConfetti),
            onComplete: weakify(self, forFunction: HotOnboardingActivateWalletFlowBuilder.closeOnboarding)
        )
        let doneNode = flow.append(doneStep)
        doneStep.configureNavigation(title: Localization.commonDone)
        doneStep.setupProgress { [weak self] in
            self?.progressValue(node: doneNode)
        }
    }
}

// MARK: - Flows

private extension HotOnboardingActivateWalletFlowBuilder {
    func setupBackupFlow() {
        var seedPhraseIntroStep = HotOnboardingSeedPhraseIntroStep(delegate: self)
        seedPhraseIntroStep.configureNavigation(
            title: Localization.commonBackup,
            leadingAction: .close(handler: { [weak self] in
                self?.closeOnboarding()
            })
        )
        let seedPhraseIntroNode = flow.append(seedPhraseIntroStep)
        seedPhraseIntroStep.setupProgress { [weak self] in
            self?.progressValue(node: seedPhraseIntroNode)
        }

        var seedPhraseRecoveryStep = HotOnboardingSeedPhraseRecoveryStep(delegate: self)
        let seedPhraseRecoveryNode = flow.append(seedPhraseRecoveryStep)
        seedPhraseRecoveryStep.configureNavigation(
            title: Localization.commonBackup,
            leadingAction: makeNavigationBackAction()
        )
        seedPhraseRecoveryStep.setupProgress { [weak self] in
            self?.progressValue(node: seedPhraseRecoveryNode)
        }

        let seedPhraseWords = getSeedPhraseWords()
        var seedPhraseValidationStep = HotOnboardingSeedPhraseValidationStep(
            seedPhraseWords: seedPhraseWords,
            onCreateWallet: weakify(self, forFunction: HotOnboardingActivateWalletFlowBuilder.openNext)
        )
        let seedPhraseValidationNode = flow.append(seedPhraseValidationStep)
        seedPhraseValidationStep.configureNavigation(
            title: Localization.commonBackup,
            leadingAction: makeNavigationBackAction()
        )
        seedPhraseValidationStep.setupProgress { [weak self] in
            self?.progressValue(node: seedPhraseValidationNode)
        }

        var doneStep = HotOnboardingSuccessStep(
            type: .seedPhaseBackupContinue,
            onAppear: {},
            onComplete: weakify(self, forFunction: HotOnboardingActivateWalletFlowBuilder.openNext)
        )
        let doneNode = flow.append(doneStep)
        doneStep.configureNavigation(title: Localization.commonBackup)
        doneStep.setupProgress { [weak self] in
            self?.progressValue(node: doneNode)
        }
    }

    func setupAccessCodeFlow() {
        var createAccessCodeStep = HotOnboardingCreateAccessCodeStep(coordinator: self, delegate: self)
        let createAccessCodeNode = flow.append(createAccessCodeStep)
        createAccessCodeStep.configureNavigation(title: Localization.accessCodeNavtitle)
        createAccessCodeStep.setupProgress { [weak self] in
            self?.progressValue(node: createAccessCodeNode)
        }
    }
}

// MARK: - Navigation

private extension HotOnboardingActivateWalletFlowBuilder {
    func openNext() {
        next()
    }

    func openPrevious() {
        back()
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

// MARK: - Private methods

private extension HotOnboardingActivateWalletFlowBuilder {
    func makeNavigationBackAction() -> HotOnboardingFlowNavBarAction {
        HotOnboardingFlowNavBarAction.back(handler: { [weak self] in
            self?.openPrevious()
        })
    }

    func getSeedPhraseWords() -> [String] {
        // [REDACTED_TODO_COMMENT]
        return [
            "brother", "embrace", "piano", "income", "feature", "real",
            "bicycle", "stairs", "glimpse", "fan", "salon", "elder",
            // brother embrace piano income feature real bicycle stairs glimpse fan salon elder
        ]
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
    func getSeedPhrase() -> [String] {
        getSeedPhraseWords()
    }

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
    func openAccesCodeSkipAlert(onAllow: @escaping () -> Void) {
        coordinator?.openAccesCodeSkipAlert(onAllow: onAllow)
    }
}

// MARK: - PushNotificationsPermissionRequestDelegate

extension HotOnboardingActivateWalletFlowBuilder: PushNotificationsPermissionRequestDelegate {
    func didFinishPushNotificationOnboarding() {
        next()
    }
}
