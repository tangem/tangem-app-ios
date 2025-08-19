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
            guard isBackupNotNeeded(for: userWalletModel) else {
                alert = makeBackupNeedsAlert()
                return
            }

            guard isAccessCodeNotNeeded(for: userWalletModel) else {
                alert = makeAccessCodeNeedsAlert(userWalletModel: userWalletModel)
                return
            }

        case .accessCode(let userWalletModel, _):
            guard isAccessCodeNotNeeded(for: userWalletModel) else {
                alert = makeAccessCodeCreationAlert()
                return
            }

        case .seedPhraseBackup(let userWalletModel):
            guard isBackupNotNeeded(for: userWalletModel) else {
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
        case .accessCode(let userWalletModel, let context):
            HotOnboardingAccessCodeFlowBuilder(
                userWalletModel: userWalletModel,
                context: context,
                coordinator: self
            )
        case .seedPhraseBackup(let userWalletModel):
            HotOnboardingBackupSeedPhraseFlowBuilder(userWalletModel: userWalletModel, coordinator: self)
        case .seedPhraseReveal(let context):
            HotOnboardingRevealSeedPhraseFlowBuilder(context: context, coordinator: self)
        }
    }
}

// MARK: - Helpers

private extension HotOnboardingViewModel {
    func isBackupNotNeeded(for userWalletModel: UserWalletModel) -> Bool {
        !userWalletModel.config.hasFeature(.mnemonicBackup)
    }

    func isAccessCodeNotNeeded(for userWalletModel: UserWalletModel) -> Bool {
        !userWalletModel.config.hasFeature(.userWalletAccessCode)
    }
}

// MARK: - Alert makers

private extension HotOnboardingViewModel {
    func makeBackupNeedsAlert() -> AlertBinder {
        AlertBuilder.makeAlert(
            title: Localization.hwBackupAlertTitle,
            message: Localization.hwBackupCloseDescription,
            primaryButton: .cancel(Text(Localization.commonNo)),
            secondaryButton: .destructive(
                Text(Localization.commonYes),
                action: weakify(self, forFunction: HotOnboardingViewModel.onBackupNeedsAlertClose)
            )
        )
    }

    func makeAccessCodeNeedsAlert(userWalletModel: UserWalletModel) -> AlertBinder {
        AlertBuilder.makeAlert(
            title: Localization.accessCodeAlertSkipTitle,
            message: Localization.accessCodeAlertSkipDescription,
            with: .init(
                primaryButton: .default(
                    Text(Localization.accessCodeAlertSkipOk),
                    action: { [weak self] in
                        self?.onAccessCodeNeedsAlertSkip(userWalletModel: userWalletModel)
                    }
                ),
                secondaryButton: .cancel()
            )
        )
    }

    func makeAccessCodeCreationAlert() -> AlertBinder {
        AlertBuilder.makeAlert(
            title: Localization.hwAccessCodeCreateAlertTitle,
            message: Localization.hwBackupCloseDescription,
            primaryButton: .cancel(Text(Localization.commonClose)),
            secondaryButton: .destructive(
                Text(Localization.commonYes),
                action: weakify(self, forFunction: HotOnboardingViewModel.onBackupCreationAlertClose)
            )
        )
    }

    func onAccessCodeNeedsAlertSkip(userWalletModel: UserWalletModel) {
        HotAccessCodeSkipHelper.append(userWalletId: userWalletModel.userWalletId)
        // Workaround to manually trigger update event for userWalletModel publisher
        userWalletModel.update(type: .backupCompleted)
        closeOnboarding()
    }

    func onBackupNeedsAlertClose() {
        closeOnboarding()
    }

    func onBackupCreationAlertClose() {
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
