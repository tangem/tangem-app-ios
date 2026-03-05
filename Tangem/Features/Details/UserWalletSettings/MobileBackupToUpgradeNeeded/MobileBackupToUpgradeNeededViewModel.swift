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
    let title = Localization.hwBackupNeedTitle
    let description = Localization.hwBackupToUpgradeDescription
    let actionTitle = Localization.hwBackupNeedAction

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

// MARK: - FloatingSheetContentViewModel

extension MobileBackupToUpgradeNeededViewModel: FloatingSheetContentViewModel {}
