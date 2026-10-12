//
//  WelcomeV2CreateWalletActionFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization

struct WelcomeV2CreateWalletActionFactory {
    struct Callbacks {
        let onHardware: () -> Void
        let onMobile: () -> Void
        let onClose: () -> Void
    }

    func make(callbacks: Callbacks) -> WelcomeV2ActionSheetViewModel {
        WelcomeV2ActionSheetViewModel(
            input: .init(
                title: Localization.introductionButtonCreateWallet,
                analyticsSheet: .create,
                items: [
                    WelcomeV2ActionSheetItem(
                        id: "hardware",
                        icon: Assets.welcomeTangemActionIcon,
                        title: Localization.introductionCreateWalletHardwareTitle,
                        subtitle: Localization.introductionCreateWalletHardwareDescription,
                        action: callbacks.onHardware
                    ),
                    WelcomeV2ActionSheetItem(
                        id: "mobile",
                        icon: DesignSystem.Icons.WalletPlus.regular24,
                        title: Localization.introductionCreateWalletSeedPhraseTitle,
                        subtitle: Localization.introductionCreateWalletSeedPhraseDescription,
                        action: callbacks.onMobile
                    ),
                ],
                onClose: callbacks.onClose
            )
        )
    }
}
