//
//  HotOnboardingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import TangemUIUtils

final class HotOnboardingViewModel: ObservableObject {
    @Published var shouldFireConfetti: Bool = false
    @Published var alert: AlertBinder?

    lazy var flowBuilder = makeFlowBuilder()

    private let input: HotOnboardingInput
    private weak var coordinator: HotOnboardingRoutable?

    init(input: HotOnboardingInput, coordinator: HotOnboardingRoutable) {
        self.input = input
        self.coordinator = coordinator
    }
}

// MARK: - Internal methods

extension HotOnboardingViewModel {
    func onDismissalAttempt() {
        // [REDACTED_TODO_COMMENT]
    }
}

// MARK: - FlowBuilder

private extension HotOnboardingViewModel {
    func makeFlowBuilder() -> HotOnboardingFlowBuilder {
        switch input.flow {
        case .walletCreate:
            HotOnboardingCreateWalletFlowBuilder(coordinator: self)
        case .walletImport:
            HotOnboardingImportWalletFlowBuilder(coordinator: self)
        case .walletActivate(let userWalletModel):
            HotOnboardingActivateWalletFlowBuilder(userWalletModel: userWalletModel, coordinator: self)
        case .accessCodeCreate(let userWalletModel):
            HotOnboardingAccessCodeFlowBuilder(
                userWalletModel: userWalletModel,
                needRequestBiometrics: true,
                coordinator: self
            )
        case .accessCodeChange(let userWalletModel):
            HotOnboardingAccessCodeFlowBuilder(
                userWalletModel: userWalletModel,
                needRequestBiometrics: false,
                coordinator: self
            )
        case .seedPhraseBackup(let userWalletModel):
            HotOnboardingBackupSeedPhraseFlowBuilder(userWalletModel: userWalletModel, coordinator: self)
        case .seedPhraseReveal(let userWalletModel):
            HotOnboardingRevealSeedPhraseFlowBuilder(
                userWalletModel: userWalletModel,
                coordinator: self
            )
        }
    }
}

// MARK: - Private methods

private extension HotOnboardingViewModel {
    func makeAccessCodeCreateSkipAlert(onSkip: @escaping () -> Void) -> AlertBinder? {
        AlertBuilder.makeAlert(
            title: Localization.accessCodeAlertSkipTitle,
            message: Localization.accessCodeAlertSkipDescription,
            with: .withPrimaryCancelButton(
                secondaryTitle: Localization.accessCodeAlertSkipOk,
                secondaryAction: onSkip
            )
        )
    }
}

// MARK: - HotOnboardingFlowRoutable

extension HotOnboardingViewModel: HotOnboardingFlowRoutable {
    func openMain() {
        coordinator?.onboardingDidFinish(userWalletModel: nil)
    }

    func openMain(userWalletModel: UserWalletModel) {
        coordinator?.onboardingDidFinish(userWalletModel: userWalletModel)
    }

    func openAccesCodeSkipAlert(onSkip: @escaping () -> Void) {
        alert = makeAccessCodeCreateSkipAlert(onSkip: onSkip)
    }

    func openConfetti() {
        shouldFireConfetti = true
    }

    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}
