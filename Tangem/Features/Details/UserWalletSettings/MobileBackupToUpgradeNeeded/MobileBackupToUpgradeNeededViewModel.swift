//
//  MobileBackupToUpgradeNeededViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import TangemMobileWalletSdk
import TangemUIUtils
import protocol TangemUI.FloatingSheetContentViewModel

final class MobileBackupToUpgradeNeededViewModel {
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    let title: String
    let description: String
    let actionTitle: String

    private lazy var authUtil = MobileAuthUtil(
        userWalletId: userWalletModel.userWalletId,
        config: userWalletModel.config,
        biometricsProvider: CommonUserWalletBiometricsProvider()
    )

    private let userWalletModel: UserWalletModel
    private let source: MobileOnboardingFlowSource
    private let onBackupFinished: () -> Void
    private weak var coordinator: MobileBackupToUpgradeNeededRoutable?

    init(
        userWalletModel: UserWalletModel,
        source: MobileOnboardingFlowSource,
        onBackupFinished: @escaping () -> Void,
        coordinator: MobileBackupToUpgradeNeededRoutable
    ) {
        self.userWalletModel = userWalletModel
        self.source = source
        self.onBackupFinished = onBackupFinished
        self.coordinator = coordinator

        if FeatureProvider.isAvailable(.mobileWalletBackup) {
            title = Localization.hwUpgradeSaveSeedTitle
            description = Localization.hwUpgradeSaveSeedDescription
            actionTitle = Localization.hwUpgradeSaveSeedAction
        } else {
            title = Localization.hwBackupNeedTitle
            description = Localization.hwBackupToUpgradeDescription
            actionTitle = Localization.hwBackupNeedAction
        }

        logScreenOpenedAnalytics()
    }
}

// MARK: - Internal methods

extension MobileBackupToUpgradeNeededViewModel {
    func onCloseTap() {
        runTask(in: self) { viewModel in
            await viewModel.close()
        }
    }

    func onBackupTap() {
        runTask(in: self) { viewModel in
            await viewModel.handleMobileBackup()
        }
    }
}

// MARK: - Private methods

private extension MobileBackupToUpgradeNeededViewModel {
    func handleMobileBackup() async {
        switch await unlock() {
        case .successful(let context):
            await openMobileBackup(context: context)
        case .failed(let error):
            AppLogger.error("Unlock failed:", error: error)
            await showErrorAlert(error)
        case .canceled:
            break
        }
    }
}

// MARK: - Unlocking

private extension MobileBackupToUpgradeNeededViewModel {
    func unlock() async -> UnlockResult {
        do {
            let result = try await authUtil.unlock()

            switch result {
            case .successful(let context):
                return .successful(context: context)

            case .canceled:
                return .canceled

            case .userWalletNeedsToDelete:
                assertionFailure("Unexpected state: .userWalletNeedsToDelete should never happen.")
                return .canceled
            }

        } catch {
            return .failed(error: error)
        }
    }

    enum UnlockResult {
        case successful(context: MobileWalletContext)
        case canceled
        case failed(error: Error)
    }
}

// MARK: - Alerts

@MainActor
private extension MobileBackupToUpgradeNeededViewModel {
    func showErrorAlert(_ error: Error) {
        let alert = error.alertBinder
        showAlert(alert)
    }

    func showAlert(_ alert: AlertBinder) {
        alertPresenter.present(alert: alert)
    }
}

// MARK: - Navigation

@MainActor
private extension MobileBackupToUpgradeNeededViewModel {
    func openMobileBackup(context: MobileWalletContext) {
        let input = MobileOnboardingInput(flow: .seedPhraseBackup(
            userWalletModel: userWalletModel,
            source: source,
            context: context
        ))
        coordinator?.openMobileOnboardingFromMobileBackupToUpgradeNeeded(input: input, onBackupFinished: onBackupFinished)
    }

    func close() {
        coordinator?.dismissMobileBackupToUpgradeNeeded()
    }
}

// MARK: - Analytics

private extension MobileBackupToUpgradeNeededViewModel {
    func logScreenOpenedAnalytics() {
        var params = source.analyticsParams

        if FeatureProvider.isAvailable(.mobileWalletBackup) {
            let statusUtil = MobileBackupStatusUtil(userWalletModel: userWalletModel)
            params[.backupManual] = .affirmativeOrNegative(for: statusUtil.hasMnemonicBackup)
            params[.backupCloud] = statusUtil.hasICloudBackup ? .done : .incomplete
        }

        Analytics.log(
            .walletSettingsNoticeBackupFirst,
            params: params,
            contextParams: .custom(userWalletModel.analyticsContextData)
        )
    }
}

// MARK: - FloatingSheetContentViewModel

extension MobileBackupToUpgradeNeededViewModel: FloatingSheetContentViewModel {}
