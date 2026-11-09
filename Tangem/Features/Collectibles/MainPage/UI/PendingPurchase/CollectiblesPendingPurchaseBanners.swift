//
//  CollectiblesPendingPurchaseBanners.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct CollectiblesPendingPurchaseBanners: View {
    @ObservedObject var viewModel: CollectiblesPendingPurchaseBannersViewModel

    var body: some View {
        NotificationBannerCarousel(items: viewModel.banners) { banner in
            Self.banner(banner.kind)
        }
        .hasClipShape(false)
        .paginationHasBackground(false)
        .paginationLayout(spacing: 0, minHeight: 32)
    }
}

private extension CollectiblesPendingPurchaseBanners {
    // MARK: - View properties

    // [REDACTED_TODO_COMMENT]
    @ViewBuilder
    static func banner(_ kind: CollectiblesPendingPurchaseBannersViewModel.Banner.Kind) -> some View {
        switch kind {
        case .paymentInProgress:
            MessageBanner(
                title: "Your payment is in progress",
                description: "Please wait a bit for transaction to complete"
            )
            .glowRing(.info)
            .slotEnd { icon(DesignSystem.Icons.Clock.regular20) }
        case .packToOpen:
            MessageBanner(
                title: "You have pack to open",
                description: "Please note, that if you have not opened pack in a few hours, you'll receive an automated refund from our partner"
            )
            .glowRing(.warning)
            .slotEnd { icon(DesignSystem.Icons.Warning.regular20) }
        }
    }

    static func icon(_ image: ImageType) -> some View {
        image.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconPrimary)
            .accessibilityHidden(true)
    }
}
