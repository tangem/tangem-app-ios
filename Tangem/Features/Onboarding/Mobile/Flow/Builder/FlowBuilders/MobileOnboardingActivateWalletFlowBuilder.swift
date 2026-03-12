//
//  MobileOnboardingActivateWalletFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization

final class MobileOnboardingActivateWalletFlowBuilder: MobileOnboardingFlowBuilder {
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor

    private var isBackupNeeded: Bool {
        userWalletModel.config.hasFeature(.mnemonicBackup) && userWalletModel.config.hasFeature(.iCloudBackup)
    }

    private var isAccessCodeNeeded: Bool {
        userWalletModel.config.userWalletAccessCodeStatus == .none
    }

    private var analyticsContextParams: Analytics.ContextParams {
        .custom(userWalletModel.analyticsContextData)
    }

    private let userWalletModel: UserWalletModel
    private let source: MobileOnboardingFlowSource
    private weak var coordinator: MobileOnboardingFlowRoutable?

    init(
        userWalletModel: UserWalletModel,
        source: MobileOnboardingFlowSource,
        coordinator: MobileOnboardingFlowRoutable
    ) {
        self.userWalletModel = userWalletModel
        self.source = source
        self.coordinator = coordinator
        super.init(hasProgressBar: true)
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
            let pushNotificationsStep = MobileOnboardingPushNotificationsStep(
                permissionManager: permissionManager,
                delegate: self
            )
            append(step: pushNotificationsStep)
        }

        let doneStep = MobileOnboardingSuccessStep(
            type: .walletReady,
            navigationTitle: Localization.commonDone,
            onAppear: weakify(self, forFunction: MobileOnboardingActivateWalletFlowBuilder.openConfetti),
            onComplete: weakify(self, forFunction: MobileOnboardingActivateWalletFlowBuilder.closeOnboarding)
        )
        append(step: doneStep)
    }
}

// MARK: - Flows

private extension MobileOnboardingActivateWalletFlowBuilder {
    func setupSeedPhraseBackupFlow() {
        let seedPhraseIntroStep = MobileOnboardingSeedPhraseIntroStep(
            userWalletModel: userWalletModel,
            source: source,
            delegate: self
        )
        append(step: seedPhraseIntroStep)

        let seedPhraseRecoveryStep = MobileOnboardingSeedPhraseRecoveryStep(
            userWalletModel: userWalletModel,
            source: source,
            delegate: self
        )
        append(step: seedPhraseRecoveryStep)

        let seedPhraseValidationStep = MobileOnboardingSeedPhraseValidationStep(
            userWalletModel: userWalletModel,
            source: source,
            delegate: self
        )
        append(step: seedPhraseValidationStep)

        let doneStep = MobileOnboardingSuccessStep(
            type: .seedPhaseBackupContinue,
            navigationTitle: Localization.commonBackup,
            onAppear: { [weak self] in
                self?.logBackupCompletedScreenOpenedAnalytics()
            },
            onComplete: { [weak self] in
                self?.logSettingAccessCodeAnalytics()
                self?.openNext()
            }
        )
        append(step: doneStep)
    }

    func setupAccessCodeFlow() {
        let accessCodeStep = MobileOnboardingAccessCodeStep(
            mode: .create(canSkip: true),
            source: source,
            delegate: self
        )
        append(step: accessCodeStep)
    }
}

// MARK: - Navigation

private extension MobileOnboardingActivateWalletFlowBuilder {
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

// MARK: - MobileOnboardingSeedPhraseIntroDelegate

extension MobileOnboardingActivateWalletFlowBuilder: MobileOnboardingSeedPhraseIntroDelegate {
    func seedPhraseIntroContinue() {
        openNext()
    }

    func seedPhraseIntroClose() {
        logSeedPhraseIntroCloseAnalytics()
        closeOnboarding()
    }
}

// MARK: - MobileOnboardingSeedPhraseRecoveryDelegate

extension MobileOnboardingActivateWalletFlowBuilder: MobileOnboardingSeedPhraseRecoveryDelegate {
    func seedPhraseRecoveryContinue() {
        openNext()
    }

    func onSeedPhraseRecoveryBack() {
        back()
    }
}

// MARK: - MobileOnboardingSeedPhraseValidationDelegate

extension MobileOnboardingActivateWalletFlowBuilder: MobileOnboardingSeedPhraseValidationDelegate {
    func didValidateSeedPhrase() {
        logSeedPhraseValidatedAnalytics()
        userWalletModel.update(type: .mnemonicBackupCompleted)
        openNext()
    }

    func onSeedPhraseValidationBack() {
        back()
    }
}

// MARK: - MobileOnboardingAccessCodeDelegate

extension MobileOnboardingActivateWalletFlowBuilder: MobileOnboardingAccessCodeDelegate {
    func getUserWalletModel() -> UserWalletModel? {
        userWalletModel
    }

    func didCompleteAccessCode() {
        openNext()
    }

    func onAccessCodeClose() {}
}

// MARK: - PushNotificationsPermissionRequestDelegate

extension MobileOnboardingActivateWalletFlowBuilder: PushNotificationsPermissionRequestDelegate {
    func didFinishPushNotificationOnboarding() {
        next()
    }
}

// MARK: - Analytics

private extension MobileOnboardingActivateWalletFlowBuilder {
    func logSeedPhraseIntroCloseAnalytics() {
        Analytics.log(.backupNoticeCanceled, contextParams: analyticsContextParams)
    }

    func logSeedPhraseValidatedAnalytics() {
        Analytics.log(
            event: .backupFinished,
            params: [.cardsCount: String(0)],
            contextParams: analyticsContextParams
        )
    }

    func logBackupCompletedScreenOpenedAnalytics() {
        Analytics.log(
            .walletSettingsBackupCompleteScreen,
            params: source.analyticsParams,
            contextParams: analyticsContextParams
        )
    }

    func logSettingAccessCodeAnalytics() {
        Analytics.log(.settingAccessCodeStarted, contextParams: analyticsContextParams)
    }
}
