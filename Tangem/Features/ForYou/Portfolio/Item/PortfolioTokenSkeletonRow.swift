//
//  PortfolioTokenSkeletonRow.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

/// Shimmer placeholder row shown in the Portfolio Review list while data loads.
struct PortfolioTokenSkeletonRow: View {
    @ScaledMetric private var iconSize: CGFloat = 40

    var body: some View {
        HStack(spacing: 12) {
            TangemShimmer()
                .variant(.custom(width: iconSize, height: iconSize))
                .clipShape(Circle())
                .frame(width: iconSize, height: iconSize)

            VStack(spacing: 4) {
                line(leading: 96, trailing: 64, height: 14)
                line(leading: 60, trailing: 44, height: 12)
            }
        }
        .padding(16)
        .portfolioTokenCard()
    }
}

private extension PortfolioTokenSkeletonRow {
    func line(leading: CGFloat, trailing: CGFloat, height: CGFloat) -> some View {
        HStack(spacing: 4) {
            shimmer(width: leading, height: height)
            Spacer(minLength: 8)
            shimmer(width: trailing, height: height)
        }
    }

    func shimmer(width: CGFloat, height: CGFloat) -> some View {
        TangemShimmer().variant(.custom(width: width, height: height))
    }
}
