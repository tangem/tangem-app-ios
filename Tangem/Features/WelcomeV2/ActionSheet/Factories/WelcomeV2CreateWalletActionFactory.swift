//
//  WelcomeV2CreateWalletActionFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets

struct WelcomeV2CreateWalletActionFactory {
    struct Callbacks {
        let onHardware: () -> Void
        let onMobile: () -> Void
        let onClose: () -> Void
    }

    func make(callbacks: Callbacks) -> WelcomeV2ActionSheetViewModel {
        WelcomeV2ActionSheetViewModel(
            input: .init(
                title: "Create wallet",
                items: [
                    WelcomeV2ActionSheetItem(
                        id: "hardware",
                        icon: Assets.welcomeTangemActionIcon,
                        title: "Tangem Card or Ring",
                        subtitle: "If you already have Tangem Wallet",
                        action: callbacks.onHardware
                    ),
                    WelcomeV2ActionSheetItem(
                        id: "mobile",
                        icon: Assets.welcomeSeedActionIcon,
                        title: "Create seed phrase wallet",
                        subtitle: "Start without a hardware wallet",
                        action: callbacks.onMobile
                    ),
                ],
                onClose: callbacks.onClose
            )
        )
    }
}
