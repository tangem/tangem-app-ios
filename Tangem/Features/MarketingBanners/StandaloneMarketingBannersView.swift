//
//  StandaloneMarketingBannersView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct StandaloneMarketingBannersView: View {
    let banners: [StandaloneMarketingBannerViewModel]

    var body: some View {
        TangemCarousel(banners) { banner in
            StandaloneMarketingBannerView(viewModel: banner)
        }
    }
}
