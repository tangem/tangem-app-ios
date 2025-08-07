//
//  HotOnboardingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
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
        switch input.flow {
        case .walletActivate(let userWalletModel):
            // [REDACTED_TODO_COMMENT]
            guard userWalletModel.config.hasFeature(.backup) else {
                alert = makeBackupNeedsAlert()
                return
            }

            guard userWalletModel.config.hasFeature(.accessCode) else {
                alert = makeAccessCodeNeedsAlert(userWalletId: userWalletModel.userWalletId)
                return
            }

        case .accessCodeCreate(let userWalletModel):
            guard userWalletModel.config.hasFeature(.accessCode) else {
                alert = makeAccessCodeNeedsAlert(userWalletId: userWalletModel.userWalletId)
                return
            }

        case .seedPhraseBackup(let userWalletModel):
            // [REDACTED_TODO_COMMENT]
            guard userWalletModel.config.hasFeature(.backup) else {
                alert = makeBackupNeedsAlert()
                return
            }

        default:
            break
        }
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

// MARK: - Alert makers

private extension HotOnboardingViewModel {
    func makeBackupNeedsAlert() -> AlertBinder {
        AlertBuilder.makeAlert(
            title: Localization.hwBackupAlertTitle,
            message: Localization.hwActivationNeedWarningDescription,
            primaryButton: .cancel(Text(Localization.commonNo)),
            secondaryButton: .destructive(
                Text(Localization.commonYes),
                action: weakify(self, forFunction: HotOnboardingViewModel.onBackupNeedsAlertClose)
            )
        )
    }

    func makeAccessCodeNeedsAlert(userWalletId: UserWalletId) -> AlertBinder {
        AlertBuilder.makeAlert(
            title: Localization.accessCodeAlertSkipTitle,
            message: Localization.accessCodeAlertSkipDescription,
            with: .withPrimaryCancelButton(
                secondaryTitle: Localization.commonClose,
                secondaryAction: { [weak self] in
                    self?.onAccessCodeNeedsAlertSkip(userWalletId: userWalletId)
                }
            )
        )
    }

    func onAccessCodeNeedsAlertSkip(userWalletId: UserWalletId) {
        AppSettings.shared.userWalletIdsWithSkippedAccessCode.appendIfNotContains(userWalletId.stringValue)
        closeOnboarding()
    }

    func onBackupNeedsAlertClose() {
        closeOnboarding()
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

    func openConfetti() {
        shouldFireConfetti = true
    }

    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}
