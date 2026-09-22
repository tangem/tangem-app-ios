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
    private weak var coordinator: MobileBackupNeededRoutable?

    init(
        userWalletModel: UserWalletModel,
        coordinator: MobileBackupNeededRoutable
    ) {
        self.userWalletModel = userWalletModel
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
            await viewModel.handleMobileBackup()
        }
    }
}

// MARK: - Private methods

private extension MobileBackupNeededViewModel {
    func handleMobileBackup() async {
        await openMobileBackupTypes()
    }
}

// MARK: - Navigation

@MainActor
private extension MobileBackupNeededViewModel {
    func openMobileBackupTypes() {
        coordinator?.openMobileBackupTypesFromMobileBackupNeeded(userWalletModel: userWalletModel)
    }

    func close() {
        coordinator?.dismissMobileBackupNeeded()
    }
}

// MARK: - FloatingSheetContentViewModel

extension MobileBackupNeededViewModel: FloatingSheetContentViewModel {}
