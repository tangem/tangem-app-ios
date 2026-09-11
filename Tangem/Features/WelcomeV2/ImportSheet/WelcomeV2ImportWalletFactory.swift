//
//  WelcomeV2ImportWalletFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemMobileWalletBackup

struct WelcomeV2ImportWalletFactory {
    struct Callbacks {
        let onRecoveryPhrase: () -> Void
        let onICloudBackup: ([MobileWalletBackup]) -> Void
        let onBack: () -> Void
        let onClose: () -> Void
    }

    func make(callbacks: Callbacks) -> WelcomeV2ImportSheetViewModel {
        WelcomeV2ImportSheetViewModel(
            input: .init(
                title: "Import existing wallet",
                subtitle: "Continue using a wallet you already own by importing or restoring",
                onRecoveryPhrase: callbacks.onRecoveryPhrase,
                onICloudBackup: callbacks.onICloudBackup,
                onBack: callbacks.onBack,
                onClose: callbacks.onClose,
                backupManager: CommonMobileWalletBackupManager(destination: .iCloud)
            )
        )
    }
}
