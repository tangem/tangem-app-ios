//
//  CollectiblesPrizeGrid+Skeleton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

extension CollectiblesPrizeGrid {
    struct Skeleton: View {
        var body: some View {
            LazyVGrid(columns: CollectiblesPrizeGrid.Metrics.columns, alignment: .leading, spacing: CollectiblesPrizeGrid.Metrics.rowSpacing) {
                ForEach(0 ..< Constants.placeholderCount, id: \.self) { _ in
                    card
                }
            }
        }
    }
}

private extension CollectiblesPrizeGrid.Skeleton {
    // MARK: - View properties

    var card: some View {
        VStack(alignment: .leading, spacing: CollectiblesPrizeCard.Metrics.contentSpacing) {
            Shimmer()
                .aspectRatio(CollectiblesPrizeCard.Metrics.artworkAspectRatio, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: CollectiblesPrizeCard.Metrics.cornerRadius, style: .continuous))

            VStack(alignment: .leading, spacing: CollectiblesPrizeCard.Metrics.detailsSpacing) {
                textLine
                textLine
            }
        }
    }

    var textLine: some View {
        Shimmer()
            .frame(width: Metrics.barWidth, height: Metrics.barHeight)
            .clipShape(Capsule())
            .frame(height: Metrics.lineHeight)
            .infinityFrame(axis: .horizontal, alignment: .leading)
    }

    enum Metrics {
        static let barWidth: CGFloat = 72
        static let barHeight: CGFloat = 14
        static let lineHeight: CGFloat = 18
    }

    enum Constants {
        static let placeholderCount = 4
    }
}
