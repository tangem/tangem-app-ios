//
//  WelcomeV2ImportWalletFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct WelcomeV2ImportWalletFactory {
    struct Callbacks {
        let onRecoveryPhrase: () -> Void
        let onICloudBackup: () -> Void
        let onBack: () -> Void
        let onClose: () -> Void
    }

    func make(callbacks: Callbacks) -> WelcomeV2ImportSheetViewModel {
        WelcomeV2ImportSheetViewModel(
            input: .init(
                title: "Import existing wallet",
                subtitle: "Continue using a wallet you already own by importing or restoring",
                items: [
                    WelcomeV2ImportSheetItem(
                        id: "recovery",
                        title: "Import recovery phrase",
                        action: callbacks.onRecoveryPhrase
                    ),
                    WelcomeV2ImportSheetItem(
                        id: "icloud",
                        title: "Restore iCloud backup",
                        action: callbacks.onICloudBackup
                    ),
                ],
                onBack: callbacks.onBack,
                onClose: callbacks.onClose
            )
        )
    }
}
