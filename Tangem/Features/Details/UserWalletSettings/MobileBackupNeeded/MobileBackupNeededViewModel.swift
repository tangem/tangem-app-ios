//
//  MobileBackupNeededViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import protocol TangemUI.FloatingSheetContentViewModel

final class MobileBackupNeededViewModel {
    let title = Localization.hwBackupNeedTitle
    let description = Localization.hwBackupToSecureDescription
    let actionTitle = Localization.hwBackupNeedAction

    private let userWalletModel: UserWalletModel
    private let source: MobileOnboardingFlowSource
    private let onBackupFinished: () -> Void
    private weak var coordinator: MobileBackupNeededRoutable?

    init(
        userWalletModel: UserWalletModel,
        source: MobileOnboardingFlowSource,
        onBackupFinished: @escaping () -> Void,
        coordinator: MobileBackupNeededRoutable
    ) {
        self.userWalletModel = userWalletModel
        self.source = source
        self.onBackupFinished = onBackupFinished
        self.coordinator = coordinator
    }
}

// MARK: - Internal methods

extension MobileBackupNeededViewModel {
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

// MARK: - Internal methods

@MainActor
private extension MobileBackupNeededViewModel {
    func openMobileBackup() {
        let input = MobileOnboardingInput(flow: .seedPhraseBackup(userWalletModel: userWalletModel, source: source))
        coordinator?.openMobileOnboardingFromMobileBackupNeeded(input: input, onBackupFinished: onBackupFinished)
    }

    func close() {
        coordinator?.dismissMobileBackupNeeded()
    }
}

// MARK: - FloatingSheetContentViewModel

extension MobileBackupNeededViewModel: FloatingSheetContentViewModel {}
