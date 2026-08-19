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
import protocol TangemUI.FloatingSheetContentViewModel

final class MobileBackupToUpgradeNeededViewModel {
    let title: String
    let description: String
    let actionTitle: String

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
            title = "Save your seed phrase before upgrading"
            description = "After the upgrade, you won’t be able to view it again. Your mobile wallet and cloud backup will be deleted, so write it down now as a backup recovery method."
            actionTitle = "Save seed phrase"
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
            await viewModel.openMobileBackup()
        }
    }
}

// MARK: - Navigation

@MainActor
private extension MobileBackupToUpgradeNeededViewModel {
    func openMobileBackup() {
        let input = MobileOnboardingInput(flow: .seedPhraseBackup(userWalletModel: userWalletModel, source: source))
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
