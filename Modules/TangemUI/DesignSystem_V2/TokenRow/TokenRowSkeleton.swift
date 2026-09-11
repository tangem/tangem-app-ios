//
//  TokenRowSkeleton.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

struct TokenRowSkeleton: View {
    private let hasGraph: Bool

    @ScaledMetric private var padding: CGFloat = TokenRowMetrics.padding
    @ScaledMetric private var spacing: CGFloat = TokenRowMetrics.skeletonSpacing
    @ScaledMetric private var lineSpacing: CGFloat = TokenRowMetrics.lineSpacing
    @ScaledMetric private var iconSize: CGFloat = TokenRowMetrics.iconWidth
    @ScaledMetric private var graphWidth: CGFloat = TokenRowMetrics.graphWidth
    @ScaledMetric private var graphHeight: CGFloat = TokenRowMetrics.graphHeight

    init(hasGraph: Bool = false) {
        self.hasGraph = hasGraph
    }

    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            Shimmer()
                .frame(size: CGSize(bothDimensions: iconSize))
                .clipShape(.circle)

            column(alignment: .leading)
            column(alignment: .trailing)

            if hasGraph {
                UtilGraph(values: [])
                    .isLoading()
                    .frame(width: graphWidth, height: graphHeight)
            }
        }
        .padding(padding)
        .accessibilityHidden(true)
    }
}

// MARK: - Leaves

private extension TokenRowSkeleton {
    func column(alignment: Shimmer.Alignment) -> some View {
        VStack(spacing: lineSpacing) {
            Shimmer()
                .variant(.text(style: .body, alignment: alignment))

            Shimmer()
                .variant(.text(style: .caption, alignment: alignment))
        }
        .frame(maxWidth: .infinity)
    }
}
