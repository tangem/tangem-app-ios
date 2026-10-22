//
//  CollectiblesPackCard.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct CollectiblesPackCard: View {
    let model: Model

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.contentSpacing) {
            artwork
            details
        }
    }
}

private extension CollectiblesPackCard {
    // MARK: - View properties

    var artwork: some View {
        Artwork(url: model.artworkURL)
            .frame(width: Metrics.packWidth, height: Metrics.packHeight)
            .infinityFrame(axis: .horizontal)
            .frame(height: Metrics.artworkHeight)
            .background(DesignSystem.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Metrics.cornerRadius, style: .continuous)
                    .strokeBorder(DesignSystem.Color.borderPrimary, lineWidth: 1)
            }
    }

    var details: some View {
        VStack(alignment: .leading, spacing: Metrics.detailsSpacing) {
            Text(model.title)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)

            priceRow
        }
    }

    var priceRow: some View {
        HStack(spacing: Metrics.priceSpacing) {
            Text(model.priceText)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)

            if let buybackText = model.buybackText {
                Badge(label: buybackText, accessibilityLabel: nil)
                    .size(.x4)
                    .variant(.outline)
            }
        }
    }
}

// MARK: - Metrics

/// Not private: `Skeleton` reads the shared values so the grid does not jump when the content arrives.
extension CollectiblesPackCard {
    enum Metrics {
        static let artworkHeight: CGFloat = 228
        static let packWidth: CGFloat = 118
        static let packHeight: CGFloat = 170
        static let cornerRadius: CGFloat = 20
        static let contentSpacing: CGFloat = 8
        static let detailsSpacing: CGFloat = 2
        static let priceSpacing: CGFloat = 4
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        HStack(alignment: .top, spacing: 12) {
            CollectiblesPackCard(model: .init(
                id: "pokemon-1",
                title: "Legendary 1",
                priceText: "$50",
                buybackText: "Buyback 85%",
                artworkURL: nil
            ))

            CollectiblesPackCard(model: .init(
                id: "sports-2",
                title: "Water 2",
                priceText: "$100",
                buybackText: nil,
                artworkURL: nil
            ))
        }
        .padding(.horizontal, 16)
    }
}
