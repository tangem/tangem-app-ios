//
//  CollectiblesPendingPurchaseBanners.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct CollectiblesPendingPurchaseBanners: View {
    @ObservedObject var viewModel: CollectiblesPendingPurchaseBannersViewModel

    var body: some View {
        NotificationBannerCarousel(items: viewModel.banners) { banner in
            bannerView(banner)
        }
        .hasClipShape(false)
        .paginationHasBackground(false)
        .paginationLayout(spacing: 0, minHeight: 32)
    }
}

private extension CollectiblesPendingPurchaseBanners {
    // MARK: - View properties

    @ViewBuilder
    func bannerView(_ banner: CollectiblesPendingPurchaseBannersViewModel.Banner) -> some View {
        switch banner.kind {
        case .paymentInProgress:
            MessageBanner(
                title: Localization.collectiblesPaymentInProgressBannerTitle,
                description: Localization.collectiblesPaymentInProgressBannerSubtitle
            )
            .glowRing(.info)
            .slotEnd { Self.icon(DesignSystem.Icons.Clock.regular20) }
        case .packToOpen:
            MessageBanner(
                title: Localization.collectiblesPackToOpenBannerTitle,
                description: Localization.collectiblesPackToOpenBannerSubtitle
            )
            .glowRing(.warning)
            .slotEnd { Self.icon(DesignSystem.Icons.Warning.regular20) }
            .primaryButton(
                MessageBannerButton(
                    title: Localization.collectiblesPackUnopenedOpenPack,
                    isLoading: viewModel.openingBannerID == banner.id,
                    action: { viewModel.openPack(bannerID: banner.id) }
                )
            )
        }
    }

    static func icon(_ image: ImageType) -> some View {
        image.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconPrimary)
            .accessibilityHidden(true)
    }
}
