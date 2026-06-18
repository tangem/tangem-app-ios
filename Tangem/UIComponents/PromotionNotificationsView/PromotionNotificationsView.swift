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
        if FeatureProvider.isAvailable(.redesign) {
            configured(NotificationBannerCarousel(items: viewModel.bannerItems))
        } else {
            configured(NotificationBannerCarousel(items: viewModel.notificationInputs) { input in
                NotificationView(input: input)
            })
        }
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
