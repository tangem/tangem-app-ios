//
//  WelcomeV2ExistingWalletActionFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization

struct WelcomeV2ExistingWalletActionFactory {
    struct Callbacks {
        let onHardware: () -> Void
        let onImport: () -> Void
        let onClose: () -> Void
    }

    func make(callbacks: Callbacks) -> WelcomeV2ActionSheetViewModel {
        WelcomeV2ActionSheetViewModel(
            input: .init(
                title: Localization.introductionButtonIHaveAWallet,
                analyticsSheet: .welcomeV2IHaveWallet,
                items: [
                    WelcomeV2ActionSheetItem(
                        id: "hardware",
                        icon: Assets.welcomeTangemActionIcon,
                        title: Localization.introductionCreateWalletHardwareTitle,
                        subtitle: Localization.introductionIHaveWalletHardwareDescription,
                        action: callbacks.onHardware
                    ),
                    WelcomeV2ActionSheetItem(
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
