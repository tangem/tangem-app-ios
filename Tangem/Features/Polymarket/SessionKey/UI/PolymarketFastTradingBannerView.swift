//
//  PolymarketFastTradingBannerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

struct PolymarketFastTradingBannerView: View {
    let banner: PolymarketFastTradingBanner
    let onAction: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        switch banner {
        case .foreignSigners:
            MessageBanner(
                title: PolymarketFastTradingStrings.foreignBannerTitle,
                description: PolymarketFastTradingStrings.foreignDescription
            )
            .variant(.warning)
            .primaryButton(MessageBannerButton(title: PolymarketFastTradingStrings.review, action: onAction))
        case .activate:
            MessageBanner(
                title: PolymarketFastTradingStrings.activationBannerTitle,
                description: PolymarketFastTradingStrings.activationBannerDescription
            )
            .glowRing(.magic)
            .primaryButton(MessageBannerButton(title: Localization.commonActivate, action: onAction))
            .closeButton(accessibilityLabel: Localization.commonClose, action: onDismiss)
        case .reactivate:
            MessageBanner(
                title: PolymarketFastTradingStrings.reactivationBannerTitle,
                description: PolymarketFastTradingStrings.reactivationBannerDescription
            )
            .variant(.warning)
            .primaryButton(MessageBannerButton(title: PolymarketFastTradingStrings.reactivate, action: onAction))
            .closeButton(accessibilityLabel: Localization.commonClose, action: onDismiss)
        case .extend(let daysLeft):
            MessageBanner(
                title: PolymarketFastTradingStrings.extensionBannerTitle(daysLeft: daysLeft),
                description: PolymarketFastTradingStrings.extensionBannerDescription
            )
            .glowRing(.magic)
            .primaryButton(MessageBannerButton(title: PolymarketFastTradingStrings.extend, action: onAction))
            .closeButton(accessibilityLabel: Localization.commonClose, action: onDismiss)
        }
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 16) {
        PolymarketFastTradingBannerView(banner: .activate, onAction: {}, onDismiss: {})
        PolymarketFastTradingBannerView(banner: .reactivate, onAction: {}, onDismiss: {})
        PolymarketFastTradingBannerView(banner: .extend(daysLeft: 12), onAction: {}, onDismiss: {})
        PolymarketFastTradingBannerView(banner: .foreignSigners, onAction: {}, onDismiss: {})
    }
    .padding(16)
}
