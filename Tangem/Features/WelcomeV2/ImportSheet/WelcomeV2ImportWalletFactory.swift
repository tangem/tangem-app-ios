//
//  WelcomeV2ImportWalletFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
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
                title: Localization.hwImportExistingWallet,
                subtitle: Localization.hwImportExistingWalletDescription,
                onRecoveryPhrase: callbacks.onRecoveryPhrase,
                onICloudBackup: callbacks.onICloudBackup,
                onBack: callbacks.onBack,
                onClose: callbacks.onClose,
                backupManager: CommonMobileWalletBackupManager(destination: .iCloud)
            )
        )
    }
}
