//
//  GachaPackCard+Skeleton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

extension GachaPackCard {
    struct Skeleton: View {
        var body: some View {
            VStack(alignment: .leading, spacing: GachaPackCard.Metrics.contentSpacing) {
                artwork

                details
            }
        }
    }
}

private extension GachaPackCard.Skeleton {
    // MARK: - View properties

    var artwork: some View {
        Shimmer()
            .frame(maxWidth: .infinity)
            .frame(height: GachaPackCard.Metrics.artworkHeight)
            .clipShape(RoundedRectangle(cornerRadius: GachaPackCard.Metrics.cornerRadius, style: .continuous))
    }

    var details: some View {
        VStack(alignment: .leading, spacing: GachaPackCard.Metrics.detailsSpacing) {
            bar(width: Metrics.titleWidth, height: Metrics.titleHeight)

            HStack(spacing: GachaPackCard.Metrics.priceSpacing) {
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

private extension GachaPackCard.Skeleton {
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
            GachaPackCard.Skeleton()
            GachaPackCard.Skeleton()
        }
        .padding(.horizontal, 16)
    }
}
