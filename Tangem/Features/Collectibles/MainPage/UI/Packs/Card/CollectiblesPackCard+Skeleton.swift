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
            textLine

            textLine
        }
    }

    var textLine: some View {
        Shimmer()
            .frame(width: Metrics.barWidth, height: Metrics.barHeight)
            .clipShape(Capsule())
            .frame(height: Metrics.lineHeight)
            .infinityFrame(axis: .horizontal, alignment: .leading)
    }
}

// MARK: - Metrics

private extension CollectiblesPackCard.Skeleton {
    enum Metrics {
        static let barWidth: CGFloat = 72
        static let barHeight: CGFloat = 14
        static let lineHeight: CGFloat = 18
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
