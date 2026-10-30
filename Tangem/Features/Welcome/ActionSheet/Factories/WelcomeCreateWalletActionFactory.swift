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
        let onAppleSignUp: () -> Void
        let onClose: () -> Void
    }

    func make(callbacks: Callbacks) -> WelcomeActionSheetViewModel {
        let appleSignUpItem: WelcomeActionSheetItem? = FeatureProvider.isAvailable(.mobileSocialLogin)
            ? WelcomeActionSheetItem(
                id: "appleLogin",
                icon: DesignSystem.Icons.LogoApple.regular20,
                title: Localization.introductionCreateWalletSocialTitle(MobileBackupConstants.appleServiceName),
                subtitle: Localization.introductionCreateWalletSocialDescription,
                action: callbacks.onAppleSignUp
            )
            : nil

        return WelcomeActionSheetViewModel(
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
                    appleSignUpItem,
                    WelcomeActionSheetItem(
                        id: "mobile",
                        icon: DesignSystem.Icons.WalletPlus.regular24,
                        title: Localization.introductionCreateWalletSeedPhraseTitle,
                        subtitle: Localization.introductionCreateWalletSeedPhraseDescription,
                        action: callbacks.onMobile
                    ),
                ].compactMap { $0 },
                onClose: callbacks.onClose
            )
        )
    }
}
