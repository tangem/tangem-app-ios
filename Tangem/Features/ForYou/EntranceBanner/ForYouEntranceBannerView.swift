//
//  ForYouEntranceBannerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemUIUtils
import TangemLocalization

struct ForYouEntranceBannerView: View {
    @ScaledMetric private var iconSize: CGFloat = 20

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            icon
            titleAndDescription
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .glowRing(.magic)
    }
}

private extension ForYouEntranceBannerView {
    var titleAndDescription: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Localization.forYouTitle)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            Text(Localization.forYouDescription)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        }
    }

    var icon: some View {
        DesignSystem.Icons.PieChart.regular20.image
            .renderingMode(.template)
            .resizable()
            .frame(width: iconSize, height: iconSize)
            .foregroundStyle(DesignSystem.Color.iconPrimary)
    }

    var background: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(DesignSystem.Color.bgOpaquePrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(DesignSystem.Color.borderPrimary, lineWidth: 1)
            )
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()
        ForYouEntranceBannerView()
            .padding(.horizontal, 16)
    }
}
