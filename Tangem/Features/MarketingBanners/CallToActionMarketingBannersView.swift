//
//  CallToActionMarketingBannersView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct CallToActionMarketingBannersView: View {
    let banners: [CallToActionMarketingBanner]
    let onAction: (CallToActionMarketingBannerAction) -> Void

    var body: some View {
        if !banners.isEmpty {
            VStack(spacing: 8) {
                ForEach(banners) { banner in
                    switch banner {
                    case .pseudoProvider(let viewModel):
                        PseudoProviderMarketingBannerView(viewModel: viewModel, onAction: onAction)
                    case .standalone(let viewModel):
                        StandaloneCallToActionMarketingBannerView(viewModel: viewModel, onAction: onAction)
                    }
                }
            }
        }
    }
}
