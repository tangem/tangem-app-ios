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

    private weak var coordinator: MobileBackupToUpgradeNeededRoutable?
    private let onBackup: () -> Void

    init(coordinator: MobileBackupToUpgradeNeededRoutable, onBackup: @escaping () -> Void) {
        self.coordinator = coordinator
        self.onBackup = onBackup
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
        close()
        onBackup()
    }

    func close() {
        coordinator?.dismissMobileBackupToUpgradeNeeded()
    }
}

// MARK: - FloatingSheetContentViewModel

extension MobileBackupToUpgradeNeededViewModel: FloatingSheetContentViewModel {}
