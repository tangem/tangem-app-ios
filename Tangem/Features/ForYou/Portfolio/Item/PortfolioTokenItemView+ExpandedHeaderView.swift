//
//  PortfolioTokenItemView+ExpandedHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

extension PortfolioTokenItemView {
    struct ExpandedHeaderView: View {
        let assetRow: ForYouTokenRowData
        let effects: PortfolioTokenGeometryEffects

        @ScaledMetric private var iconSize: CGFloat = 16
        @ScaledMetric private var chevronSize: CGFloat = 20

        var body: some View {
            VStack(spacing: 0) {
                header
                divider
            }
        }
    }
}

private extension PortfolioTokenItemView.ExpandedHeaderView {
    var header: some View {
        HStack(spacing: 12) {
            icon
            HStack(spacing: 4) {
                Text(assetRow.symbol)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                    .minimumScaleFactor(1)
                    .matchedGeometryEffect(effects.symbol)
                dotSeparator
                summary
            }
            .lineLimit(1)

            Spacer(minLength: 8)

            DesignSystem.Icons.ChevronCollapse.regular20.image
                .renderingMode(.template)
                .resizable()
                .frame(width: chevronSize, height: chevronSize)
                .foregroundStyle(DesignSystem.Color.iconPrimary)
        }
        .padding(16)
    }

    @ViewBuilder
    var summary: some View {
        switch assetRow.end {
        case .values(let fiat, let percent):
            Text(fiat)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
            dotSeparator
            Text(percent)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
        case .unavailable(let label):
            Text(AppConstants.enDashSign)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
            dotSeparator
            Text(label)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textStatusWarning)
        }
    }

    @ViewBuilder
    var icon: some View {
        if let tokenIconInfo = assetRow.tokenIconInfo {
            TokenIcon(
                tokenIconInfo: tokenIconInfo,
                size: CGSize(width: iconSize, height: iconSize),
                isWithOverlays: false
            )
        } else {
            DesignSystem.Icons.tokenError.image
                .resizable()
                .scaledToFit()
                .foregroundStyle(DesignSystem.Color.iconPrimary)
                .matchedGeometryEffect(effects.icon)
                .frame(width: iconSize, height: iconSize)
        }
    }

    var divider: some View {
        Separator(color: DesignSystem.Color.borderSecondary)
            .padding(.horizontal, 16)
    }

    var dotSeparator: some View {
        Circle()
            .fill(DesignSystem.Color.iconTertiary)
            .frame(width: 3, height: 3)
    }
}
