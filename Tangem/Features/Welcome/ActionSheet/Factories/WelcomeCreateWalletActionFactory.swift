//
//  WelcomeCreateWalletActionFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization

struct WelcomeCreateWalletActionFactory {
    struct Callbacks {
        let onHardware: () -> Void
        let onMobile: () -> Void
        let onClose: () -> Void
    }

    func make(callbacks: Callbacks) -> WelcomeActionSheetViewModel {
        WelcomeActionSheetViewModel(
            input: .init(
                title: Localization.introductionButtonCreateWallet,
                analyticsSheet: .create,
                items: [
                    WelcomeActionSheetItem(
                        id: "hardware",
                        icon: Assets.welcomeTangemActionIcon,
                        title: Localization.introductionCreateWalletHardwareTitle,
                        subtitle: Localization.introductionCreateWalletHardwareDescription,
                        action: callbacks.onHardware
                    ),
                    WelcomeActionSheetItem(
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
