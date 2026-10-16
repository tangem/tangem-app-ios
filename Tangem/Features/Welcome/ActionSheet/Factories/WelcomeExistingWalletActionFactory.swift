//
//  WelcomeExistingWalletActionFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization

struct WelcomeExistingWalletActionFactory {
    struct Callbacks {
        let onHardware: () -> Void
        let onImport: () -> Void
        let onClose: () -> Void
    }

    func make(callbacks: Callbacks) -> WelcomeActionSheetViewModel {
        WelcomeActionSheetViewModel(
            input: .init(
                title: Localization.introductionButtonIHaveAWallet,
                analyticsSheet: .welcomeIHaveWallet,
                items: [
                    WelcomeActionSheetItem(
                        id: "hardware",
                        icon: Assets.welcomeTangemActionIcon,
                        title: Localization.introductionCreateWalletHardwareTitle,
                        subtitle: Localization.introductionIHaveWalletHardwareDescription,
                        action: callbacks.onHardware
                    ),
                    WelcomeActionSheetItem(
                        id: "import",
                        icon: DesignSystem.Icons.ArrowDown.regular24,
                        title: Localization.hwImportExistingWallet,
                        subtitle: Localization.introductionCreateWalletSeedPhraseDescription,
                        action: callbacks.onImport
                    ),
                ],
                onClose: callbacks.onClose
            )
        )
    }
}
