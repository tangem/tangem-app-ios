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
        case .walletActivate(let userWalletModel, _):
            if isBackupNeeded(for: userWalletModel) {
                alert = makeBackupNeedsAlert()
                return
            }

            if isAccessCodeNeeded(for: userWalletModel) {
                alert = makeAccessCodeNeedsAlert(userWalletModel: userWalletModel)
                return
            }

        case .accessCode(let userWalletModel, _, _):
            if isAccessCodeNeeded(for: userWalletModel) {
                alert = makeAccessCodeCreationAlert()
                return
            }

        case .seedPhraseBackup(let userWalletModel, _), .seedPhraseBackupToUpgrade(let userWalletModel, _, _):
            if isBackupNeeded(for: userWalletModel) {
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
        case .walletImport(let source):
            MobileOnboardingImportWalletFlowBuilder(source: source, coordinator: self)
        case .walletActivate(let userWalletModel, let source):
            MobileOnboardingActivateWalletFlowBuilder(userWalletModel: userWalletModel, source: source, coordinator: self)
        case .accessCode(let userWalletModel, let source, let context):
            MobileOnboardingAccessCodeFlowBuilder(
                userWalletModel: userWalletModel,
                source: source,
                context: context,
                coordinator: self
            )
        case .seedPhraseBackup(let userWalletModel, let source):
            MobileOnboardingBackupSeedPhraseFlowBuilder(userWalletModel: userWalletModel, source: source, coordinator: self)
        case .seedPhraseReveal(let context):
            MobileOnboardingRevealSeedPhraseFlowBuilder(context: context, coordinator: self)
        case .seedPhraseBackupToUpgrade(let userWalletModel, let source, let onContinue):
            MobileOnboardingBackupToUpgradeSeedPhraseFlowBuilder(
                userWalletModel: userWalletModel,
                source: source,
                coordinator: self,
                onContinue: onContinue
            )
        }
    }
}

// MARK: - Helpers

private extension MobileOnboardingViewModel {
    func isBackupNeeded(for userWalletModel: UserWalletModel) -> Bool {
        userWalletModel.config.hasFeature(.mnemonicBackup)
    }

    func isAccessCodeNeeded(for userWalletModel: UserWalletModel) -> Bool {
        userWalletModel.config.userWalletAccessCodeStatus == .none
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
        userWalletModel.update(type: .accessCodeDidSkip)
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

    func completeOnboarding() {
        coordinator?.mobileOnboardingDidComplete()
    }

    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}
