//
//  CollectiblesPackCard+Skeleton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils
import TangemAssets
import TangemUI

extension CollectiblesPackCard {
    struct Skeleton: View {
        var body: some View {
            VStack(alignment: .leading, spacing: CollectiblesPackCard.Metrics.contentSpacing) {
                artwork

                details
            }
        }
    }
}

private extension CollectiblesPackCard.Skeleton {
    // MARK: - View properties

    var artwork: some View {
        Shimmer()
            .infinityFrame(axis: .horizontal)
            .frame(height: CollectiblesPackCard.Metrics.artworkHeight)
            .clipShape(RoundedRectangle(cornerRadius: CollectiblesPackCard.Metrics.cornerRadius, style: .continuous))
    }

    var details: some View {
        VStack(alignment: .leading, spacing: CollectiblesPackCard.Metrics.detailsSpacing) {
            bar(width: Metrics.titleWidth, height: Metrics.titleHeight)

            HStack(spacing: CollectiblesPackCard.Metrics.priceSpacing) {
                bar(width: Metrics.priceWidth, height: Metrics.badgeHeight)
                bar(width: Metrics.badgeWidth, height: Metrics.badgeHeight)
            }
        }
    }

    func bar(width: CGFloat, height: CGFloat) -> some View {
        Shimmer()
            .frame(width: width, height: height)
            .clipShape(Capsule())
    }
}

// MARK: - Metrics

private extension CollectiblesPackCard.Skeleton {
    enum Metrics {
        static let titleWidth: CGFloat = 96
        static let titleHeight: CGFloat = 14
        static let priceWidth: CGFloat = 28
        static let badgeWidth: CGFloat = 90
        static let badgeHeight: CGFloat = 16
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        HStack(alignment: .top, spacing: 12) {
            CollectiblesPackCard.Skeleton()
            CollectiblesPackCard.Skeleton()
        }
        .padding(.horizontal, 16)
    }
}
