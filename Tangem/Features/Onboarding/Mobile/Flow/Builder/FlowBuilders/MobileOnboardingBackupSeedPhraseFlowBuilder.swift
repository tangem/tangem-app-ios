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
        super.init()
    }

    override func setupFlow() {
        let seedPhraseIntroStep = MobileOnboardingSeedPhraseIntroStep(userWalletModel: userWalletModel, source: source, delegate: self)
            .configureNavBar(
                title: Localization.commonBackup,
                leadingAction: .close(handler: { [weak self] in
                    self?.logSeedPhraseIntroCloseAnalytics()
                    self?.closeOnboarding()
                })
            )
        append(step: seedPhraseIntroStep)

        let seedPhraseRecoveryStep = MobileOnboardingSeedPhraseRecoveryStep(userWalletModel: userWalletModel, source: source, delegate: self)
        seedPhraseRecoveryStep.configureNavBar(
            title: Localization.commonBackup,
            leadingAction: navBarBackAction
        )
        append(step: seedPhraseRecoveryStep)

        let seedPhraseValidationStep = MobileOnboardingSeedPhraseValidationStep(
            userWalletModel: userWalletModel,
            source: source,
            delegate: self
        )
        seedPhraseValidationStep.configureNavBar(
            title: Localization.commonBackup,
            leadingAction: navBarBackAction
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
            onAppear: { [weak self] in
                self?.logBackupCompletedScreenOpenedAnalytics()
                self?.openConfetti()
            },
            onComplete: weakify(self, forFunction: MobileOnboardingBackupSeedPhraseFlowBuilder.completeOnboarding)
        )
        step.configureNavBar(title: Localization.commonBackup)
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
}

// MARK: - MobileOnboardingSeedPhraseRecoveryDelegate

extension MobileOnboardingBackupSeedPhraseFlowBuilder: MobileOnboardingSeedPhraseRecoveryDelegate {
    func seedPhraseRecoveryContinue() {
        openNext()
    }
}

// MARK: - MobileOnboardingSeedPhraseValidationDelegate

extension MobileOnboardingBackupSeedPhraseFlowBuilder: MobileOnboardingSeedPhraseValidationDelegate {
    func didValidateSeedPhrase() {
        logSeedPhraseValidatedAnalytics()
        userWalletModel.update(type: .mnemonicBackupCompleted)
        openNext()
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
