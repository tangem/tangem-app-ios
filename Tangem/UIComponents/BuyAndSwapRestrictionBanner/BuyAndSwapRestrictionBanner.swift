//
//  BuyAndSwapRestrictionBanner.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct BuyAndSwapRestrictionBanner: View {
    var regionName: String?

    @StateObject private var viewModel = BuyAndSwapRestrictionBannerViewModel()

    @ScaledMetric private var iconSize: CGFloat = 20

    var body: some View {
        MessageBanner(
            title: Localization.buySwapRegionRestrictionTitle,
            description: regionName.map(Localization.buySwapRegionRestrictionDescriptionRegion) ?? viewModel.description
        )
        .variant(.warning)
        .glowRing(.warning)
        .slotEnd { infoIcon }
        .task {
            guard regionName == nil else {
                return
            }

            await viewModel.resolveRegion()
        }
    }

    private var infoIcon: some View {
        DesignSystem.Icons.Info.regular20.image
            .renderingMode(.template)
            .resizable()
            .frame(size: CGSize(bothDimensions: iconSize))
            .foregroundStyle(DesignSystem.Color.iconPrimary)
            .accessibilityHidden(true)
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 8) {
        BuyAndSwapRestrictionBanner()
        BuyAndSwapRestrictionBanner(regionName: "Armenia")
    }
    .padding(.horizontal, 16)
}
