//
//  MobileOnboardingTangemPayFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization

final class MobileOnboardingTangemPayFlowBuilder: MobileOnboardingFlowBuilder {
    private var isBackupNeeded: Bool {
        userWalletModel.config.hasFeature(.mnemonicBackup) && userWalletModel.config.hasFeature(.iCloudBackup)
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

        append(step: MobileOnboardingAccessCodeStep(mode: .create(canSkip: true), source: source, delegate: self))
    }
}

// MARK: - Flows

private extension MobileOnboardingTangemPayFlowBuilder {
    func setupSeedPhraseBackupFlow() {
        append(step: MobileOnboardingSeedPhraseIntroStep(userWalletModel: userWalletModel, source: source, delegate: self))

        append(step: MobileOnboardingSeedPhraseRecoveryStep(userWalletModel: userWalletModel, source: source, delegate: self))

        append(step: MobileOnboardingSeedPhraseValidationStep(userWalletModel: userWalletModel, source: source, delegate: self))

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
}

// MARK: - Navigation

private extension MobileOnboardingTangemPayFlowBuilder {
    func openNext() {
        next()
    }

    func openMain() {
        coordinator?.openMain(userWalletModel: userWalletModel)
    }

    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}

// MARK: - MobileOnboardingSeedPhraseIntroDelegate

extension MobileOnboardingTangemPayFlowBuilder: MobileOnboardingSeedPhraseIntroDelegate {
    func seedPhraseIntroContinue() {
        openNext()
    }

    func seedPhraseIntroClose() {
        logSeedPhraseIntroCloseAnalytics()
        closeOnboarding()
    }
}

// MARK: - MobileOnboardingSeedPhraseRecoveryDelegate

extension MobileOnboardingTangemPayFlowBuilder: MobileOnboardingSeedPhraseRecoveryDelegate {
    func seedPhraseRecoveryContinue() {
        openNext()
    }

    func onSeedPhraseRecoveryBack() {
        back()
    }
}

// MARK: - MobileOnboardingSeedPhraseValidationDelegate

extension MobileOnboardingTangemPayFlowBuilder: MobileOnboardingSeedPhraseValidationDelegate {
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

extension MobileOnboardingTangemPayFlowBuilder: MobileOnboardingAccessCodeDelegate {
    func getUserWalletModel() -> UserWalletModel? {
        userWalletModel
    }

    func didCompleteAccessCode() {
        openMain()
    }

    func onAccessCodeClose() {}
}

// MARK: - Analytics

private extension MobileOnboardingTangemPayFlowBuilder {
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
