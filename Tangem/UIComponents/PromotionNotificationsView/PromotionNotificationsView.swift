//
//  PromotionNotificationsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

struct PromotionNotificationsView: View {
    @ObservedObject var viewModel: PromotionNotificationsViewModel

    var body: some View {
        configured(
            NotificationBannerCarousel(items: viewModel.bannerItems) { item in
                NotificationMessageBanner(
                    bannerType: item.bannerType,
                    variant: item.variant,
                    ring: item.ring,
                    accessibilityIdentifier: item.accessibilityIdentifier
                )
            }
        )
    }

    private func configured<Item, BannerView: View>(
        _ carousel: NotificationBannerCarousel<Item, BannerView>
    ) -> some View {
        carousel
            .hasClipShape(false)
            .paginationHasBackground(false)
            .currentIndexHasChanged(viewModel.carouselIndexHasChanged)
            .onScreenVisibilityChange(viewModel.onScreenVisibilityChange)
    }
}
