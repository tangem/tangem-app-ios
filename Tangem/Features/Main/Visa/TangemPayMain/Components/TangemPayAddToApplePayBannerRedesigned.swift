//
//  TangemPayAddToApplePayBannerRedesigned.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

struct TangemPayAddToApplePayBannerRedesigned: View {
    let openAction: () -> Void
    let closeAction: () -> Void

    var body: some View {
        MessageBanner(
            title: Localization.tangempayCardDetailsOpenWalletNotificationTitleApple,
            description: Localization.tangempayCardDetailsOpenWalletNotificationSubtitleApple
        )
        .glowRing(.magic)
        .slotEnd {
            MessageBannerCloseButton(accessibilityLabel: Localization.commonClose, action: closeAction)
                .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.addToApplePayGuideBannerCloseButton)
        }
        .onTap(openAction)
        .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.addToApplePayGuideBanner)
    }
}
