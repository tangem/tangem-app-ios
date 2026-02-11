//
//  MobileOnboardingBackupSeedPhraseFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

class MobileOnboardingBackupSeedPhraseFlowBuilder: MobileOnboardingFlowBuilder {
    private var analyticsContextParams: Analytics.ContextParams {
        .custom(userWalletModel.analyticsContextData)
    }

    private let userWalletModel: UserWalletModel
    private let source: MobileOnboardingFlowSource
    private(set) weak var coordinator: MobileOnboardingFlowRoutable?

    init(
        userWalletModel: UserWalletModel,
        source: MobileOnboardingFlowSource,
        coordinator: MobileOnboardingFlowRoutable
    ) {
        self.userWalletModel = userWalletModel
        self.source = source
        self.coordinator = coordinator
        super.init(hasProgressBar: false)
    }

    override func setupFlow() {
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

        append(step: completeStep())
    }

    func completeStep() -> Step {
        makeDoneStep()
    }
}

// MARK: - Private methods

private extension MobileOnboardingBackupSeedPhraseFlowBuilder {
    func makeDoneStep() -> Step {
        let successType: MobileOnboardingSuccessViewModel.SuccessType
        if case .walletSettings(let action) = source, action == .accessCode {
            successType = .seedPhaseBackupContinue
        } else {
            successType = .seedPhaseBackupFinish
        }

        let step = MobileOnboardingSuccessStep(
            type: successType,
            navigationTitle: Localization.commonBackup,
            onAppear: { [weak self] in
                self?.logBackupCompletedScreenOpenedAnalytics()
                self?.openConfetti()
            },
            onComplete: weakify(self, forFunction: MobileOnboardingBackupSeedPhraseFlowBuilder.completeOnboarding)
        )
        return step
    }
}

// MARK: - Navigation

private extension MobileOnboardingBackupSeedPhraseFlowBuilder {
    func openNext() {
        next()
    }

    func openConfetti() {
        coordinator?.openConfetti()
    }

    func completeOnboarding() {
        coordinator?.completeOnboarding()
    }

    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}

// MARK: - MobileOnboardingSeedPhraseIntroDelegate

extension MobileOnboardingBackupSeedPhraseFlowBuilder: MobileOnboardingSeedPhraseIntroDelegate {
    func seedPhraseIntroContinue() {
        openNext()
    }

    func seedPhraseIntroClose() {
        logSeedPhraseIntroCloseAnalytics()
        closeOnboarding()
    }
}

// MARK: - MobileOnboardingSeedPhraseRecoveryDelegate

extension MobileOnboardingBackupSeedPhraseFlowBuilder: MobileOnboardingSeedPhraseRecoveryDelegate {
    func seedPhraseRecoveryContinue() {
        openNext()
    }

    func onSeedPhraseRecoveryBack() {
        back()
    }
}

// MARK: - MobileOnboardingSeedPhraseValidationDelegate

extension MobileOnboardingBackupSeedPhraseFlowBuilder: MobileOnboardingSeedPhraseValidationDelegate {
    func didValidateSeedPhrase() {
        logSeedPhraseValidatedAnalytics()
        userWalletModel.update(type: .mnemonicBackupCompleted)
        openNext()
    }

    func onSeedPhraseValidationBack() {
        back()
    }
}

// MARK: - Analytics

extension MobileOnboardingBackupSeedPhraseFlowBuilder {
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
}
