//
//  PromotionNotificationsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct PromotionNotificationsView: View {
    @ObservedObject var viewModel: PromotionNotificationsViewModel

    var body: some View {
        NotificationBannerCarousel(items: viewModel.notificationInputs) { input in
            NotificationView(input: input)
        }
        .paginationHasBackground(false)
        .currentIndexHasChanged(viewModel.carouselIndexHasChanged)
    }
}
