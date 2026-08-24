//
//  WelcomeV2ExistingWalletActionFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets

struct WelcomeV2ExistingWalletActionFactory {
    struct Callbacks {
        let onHardware: () -> Void
        let onImport: () -> Void
        let onClose: () -> Void
    }

    func make(callbacks: Callbacks) -> WelcomeV2ActionSheetViewModel {
        WelcomeV2ActionSheetViewModel(
            input: .init(
                title: "I have a wallet",
                items: [
                    WelcomeV2ActionSheetItem(
                        id: "hardware",
                        icon: Assets.welcomeTangemActionIcon,
                        title: "Tangem Card or Ring",
                        subtitle: "Use Tangem Wallet to enter the app",
                        action: callbacks.onHardware
                    ),
                    WelcomeV2ActionSheetItem(
                        id: "import",
                        icon: Assets.welcomeSeedActionIcon,
                        title: "Import existing wallet",
                        subtitle: "Start without a hardware wallet",
                        action: callbacks.onImport
                    ),
                ],
                onClose: callbacks.onClose
            )
        )
    }
}
