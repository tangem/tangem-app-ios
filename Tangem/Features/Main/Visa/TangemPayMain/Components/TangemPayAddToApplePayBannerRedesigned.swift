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

struct TangemPayAddToApplePayBannerRedesigned: View {
    let openAction: () -> Void
    let closeAction: () -> Void

    var body: some View {
        NotificationBanner(bannerType: bannerType, accessibilityIdentifier: nil)
            .overlay {
                RoundedRectangle(cornerRadius: DesignSystem.Tokens.CornerRadius._300)
                    .strokeBorder(DesignSystem.Tokens.Theme.Border.primary, lineWidth: DesignSystem.Tokens.BorderWidth.sm)
                    .allowsHitTesting(false)
            }
    }

    private var bannerType: NotificationBanner.BannerType {
        .promo(
            .text(.init(
                title: AttributedString(Localization.tangempayCardDetailsOpenWalletNotificationTitleApple),
                subtitle: AttributedString(Localization.tangempayCardDetailsOpenWalletNotificationSubtitleApple)
            )),
            .tappable(NotificationBanner.Action { [openAction] in openAction() }),
            NotificationBanner.CloseAction { [closeAction] in closeAction() },
            .bannerMagic,
            .leading
        )
    }
}
