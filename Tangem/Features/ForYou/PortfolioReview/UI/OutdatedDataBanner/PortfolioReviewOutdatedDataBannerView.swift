//
//  PortfolioReviewOutdatedDataBannerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

/// Shown above the Portfolio Review section when displayed balances are stale cache.
struct PortfolioReviewOutdatedDataBannerView: View {
    @ObservedObject var viewModel: PortfolioReviewViewModel

    var body: some View {
        if viewModel.showsOutdatedDataBanner {
            OutdatedDataBanner()
        }
    }
}

/// Split from the observing wrapper so previews can render it directly.
private struct OutdatedDataBanner: View {
    @ScaledMetric private var iconSize: CGFloat = 20

    var body: some View {
        TangemMessageBanner(title: Localization.warningSomeTokenBalancesNotUpdated)
            .variant(.warning)
            .showGlowRing(false)
            .titleLineLimit(2)
            .slotEnd { icon }
    }

    private var icon: some View {
        DesignSystem.Icons.CloudExclamation.regular20.image
            .renderingMode(.template)
            .resizable()
            .frame(width: iconSize, height: iconSize)
            .foregroundStyle(DesignSystem.Color.iconPrimary)
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()
        OutdatedDataBanner()
            .padding(.horizontal, 16)
    }
}
