//
//  MobileOnboardingViewModel.swift
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

final class MobileOnboardingViewModel: ObservableObject {
    @Published var shouldFireConfetti: Bool = false
    @Published var alert: AlertBinder?

    lazy var flowBuilder = makeFlowBuilder()

    private let input: MobileOnboardingInput
    private weak var coordinator: MobileOnboardingRoutable?

    init(input: MobileOnboardingInput, coordinator: MobileOnboardingRoutable) {
        self.input = input
        self.coordinator = coordinator
    }
}

// MARK: - Internal methods

extension MobileOnboardingViewModel {
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

private extension MobileOnboardingViewModel {
    func makeFlowBuilder() -> MobileOnboardingFlowBuilder {
        switch input.flow {
        case .walletImport:
            MobileOnboardingImportWalletFlowBuilder(coordinator: self)
        case .walletActivate(let userWalletModel):
            MobileOnboardingActivateWalletFlowBuilder(userWalletModel: userWalletModel, coordinator: self)
        case .accessCode(let userWalletModel, let context):
            MobileOnboardingAccessCodeFlowBuilder(
                userWalletModel: userWalletModel,
                context: context,
                coordinator: self
            )
        case .seedPhraseBackup(let userWalletModel):
            MobileOnboardingBackupSeedPhraseFlowBuilder(userWalletModel: userWalletModel, coordinator: self)
        case .seedPhraseReveal(let context):
            MobileOnboardingRevealSeedPhraseFlowBuilder(context: context, coordinator: self)
        }
    }
}

// MARK: - Helpers

private extension MobileOnboardingViewModel {
    func isBackupNotNeeded(for userWalletModel: UserWalletModel) -> Bool {
        !userWalletModel.config.hasFeature(.mnemonicBackup)
    }

    func isAccessCodeNotNeeded(for userWalletModel: UserWalletModel) -> Bool {
        !userWalletModel.config.hasFeature(.userWalletAccessCode)
    }
}

// MARK: - Alert makers

private extension MobileOnboardingViewModel {
    func makeBackupNeedsAlert() -> AlertBinder {
        AlertBuilder.makeAlert(
            title: Localization.hwBackupAlertTitle,
            message: Localization.hwBackupCloseDescription,
            primaryButton: .cancel(Text(Localization.commonNo)),
            secondaryButton: .destructive(
                Text(Localization.commonYes),
                action: weakify(self, forFunction: MobileOnboardingViewModel.onBackupNeedsAlertClose)
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
                action: weakify(self, forFunction: MobileOnboardingViewModel.onBackupCreationAlertClose)
            )
        )
    }

    func onAccessCodeNeedsAlertSkip(userWalletModel: UserWalletModel) {
        MobileAccessCodeSkipHelper.append(userWalletId: userWalletModel.userWalletId)
        // Workaround to manually trigger update event for userWalletModel publisher
        userWalletModel.update(type: .backupCompleted)
        closeOnboarding()
    }

    func onBackupNeedsAlertClose() {
        Analytics.log(.backupNoticeCanceled, contextParams: .custom(.mobileWallet))

        closeOnboarding()
    }

    func onBackupCreationAlertClose() {
        closeOnboarding()
    }
}

// MARK: - MobileOnboardingFlowRoutable

extension MobileOnboardingViewModel: MobileOnboardingFlowRoutable {
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
