//
//  CollectiblesAccountView+Banners.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension CollectiblesAccountView {
    struct Banners: View {
        let relinkBannerViewModel: CollectiblesRelinkBannerViewModel?
        let pendingPurchaseBannersViewModel: CollectiblesPendingPurchaseBannersViewModel?

        var body: some View {
            relinkBannerViewModel.map(CollectiblesRelinkBanner.init)
            pendingPurchaseBannersViewModel.map(CollectiblesPendingPurchaseBanners.init)
        }

        func load() async {
            await pendingPurchaseBannersViewModel?.load()
        }
    }
}
