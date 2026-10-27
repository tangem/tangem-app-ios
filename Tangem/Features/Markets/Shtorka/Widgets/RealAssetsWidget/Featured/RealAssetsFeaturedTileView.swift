//
//  RealAssetsFeaturedTileView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemUI
import TangemUIUtils

struct RealAssetsFeaturedTileView: View {
    let item: RealAssetsFeaturedItem

    @ScaledMetric private var tileWidth: CGFloat = RealAssetsFeaturedTileLayout.width

    var body: some View {
        SwiftUI.Button(action: item.onTap) {
            content
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsFeaturedAssetItem(uniqueId: item.name))
    }
}

// MARK: - Subviews

private extension RealAssetsFeaturedTileView {
    var content: some View {
        VStack(alignment: .leading, spacing: .zero) {
            icon

            FixedSpacer(height: RealAssetsFeaturedTileLayout.iconBottomSpacing)

            titleRow

            FixedSpacer(height: RealAssetsFeaturedTileLayout.lineSpacing)

            priceRow
        }
        .frame(width: tileWidth, alignment: .topLeading)
        .padding(RealAssetsFeaturedTileLayout.padding)
        .background(DesignSystem.Color.bgTransparentPrimary, in: .rect(cornerRadius: RealAssetsFeaturedTileLayout.cornerRadius))
    }

    var icon: some View {
        TokenIconV2(
            tokenIconInfo: .remote(name: item.name, imageURL: item.imageURL),
            size: .size40
        )
    }

    var titleRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: RealAssetsFeaturedTileLayout.textSpacing) {
            Text(item.name)
                .lineLimit(1)
                .truncationMode(.middle)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            Text(item.symbol)
                .lineLimit(1)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        }
    }

    var priceRow: some View {
        HStack(spacing: RealAssetsFeaturedTileLayout.textSpacing) {
            Text(item.price)
                .lineLimit(1)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)

            PriceChangeView(state: item.priceChangeState, useRedesignColors: true)
        }
    }
}

struct RealAssetsFeaturedTileSkeletonView: View {
    @ScaledMetric private var tileWidth: CGFloat = RealAssetsFeaturedTileLayout.width
    @ScaledMetric private var scaleFactor: CGFloat = 1

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Shimmer()
                .variant(.custom(width: 40 * scaleFactor, height: 40 * scaleFactor))

            FixedSpacer(height: RealAssetsFeaturedTileLayout.iconBottomSpacing)

            Shimmer()
                .variant(.custom(width: 95 * scaleFactor, height: 20 * scaleFactor))

            FixedSpacer(height: RealAssetsFeaturedTileLayout.lineSpacing)

            Shimmer()
                .variant(.custom(width: 110 * scaleFactor, height: 16 * scaleFactor))
        }
        .frame(width: tileWidth, alignment: .topLeading)
        .padding(RealAssetsFeaturedTileLayout.padding)
        .background(DesignSystem.Color.bgTransparentPrimary, in: .rect(cornerRadius: RealAssetsFeaturedTileLayout.cornerRadius))
        .allowsHitTesting(false)
    }
}

// MARK: - Layout

private enum RealAssetsFeaturedTileLayout {
    static let width: CGFloat = 154
    static let padding: CGFloat = 12
    static let cornerRadius: CGFloat = 24
    static let iconBottomSpacing: CGFloat = 22
    static let lineSpacing: CGFloat = 4
    static let textSpacing: CGFloat = 4
}

// MARK: - Previews

#Preview {
    HStack(spacing: 8) {
        RealAssetsFeaturedTileView(
            item: RealAssetsFeaturedItem(
                id: "apple-xstock",
                name: "Apple",
                symbol: "AAPL",
                imageURL: nil,
                price: "$315.5",
                priceChangeState: .loaded(changeType: .negative, text: "2.08%"),
                onTap: {}
            )
        )

        RealAssetsFeaturedTileSkeletonView()
    }
    .padding()
}
