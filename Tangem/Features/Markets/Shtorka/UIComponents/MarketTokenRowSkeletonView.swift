//
//  MarketTokenRowSkeletonView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils

struct MarketTokenRowSkeletonView: View {
    @ScaledMetric private var iconSize: CGFloat = 40
    @ScaledMetric private var horizontalPadding: CGFloat = SizeUnit.x4.value
    @ScaledMetric private var verticalPadding: CGFloat = SizeUnit.x3.value

    @ScaledMetric private var primaryBarHeight: CGFloat = 20
    @ScaledMetric private var primaryLeadingBarWidth: CGFloat = 110
    @ScaledMetric private var primaryTrailingBarWidth: CGFloat = 64

    @ScaledMetric private var secondaryBarHeight: CGFloat = 16
    @ScaledMetric private var secondaryBarWidth: CGFloat = 50

    var body: some View {
        TangemTwoLineRowLayout(
            icon: { iconView },
            primaryLeading: { primaryLeadingSkeleton },
            primaryTrailing: { primaryTrailingSkeleton },
            secondaryLeading: { secondaryLeadingSkeleton },
            secondaryTrailing: { secondaryTrailingSkeleton }
        )
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
    }

    private var iconView: some View {
        IconView(
            url: nil,
            size: CGSize(bothDimensions: iconSize),
            forceKingfisher: false
        )
    }

    private var primaryLeadingSkeleton: some View {
        SkeletonView()
            .frame(width: primaryLeadingBarWidth, height: primaryBarHeight)
            .cornerRadius(primaryBarHeight / 2)
    }

    private var primaryTrailingSkeleton: some View {
        SkeletonView()
            .frame(width: primaryTrailingBarWidth, height: primaryBarHeight)
            .cornerRadius(primaryBarHeight / 2)
    }

    private var secondaryLeadingSkeleton: some View {
        SkeletonView()
            .frame(width: secondaryBarWidth, height: secondaryBarHeight)
            .cornerRadius(secondaryBarHeight / 2)
    }

    private var secondaryTrailingSkeleton: some View {
        SkeletonView()
            .frame(width: secondaryBarWidth, height: secondaryBarHeight)
            .cornerRadius(secondaryBarHeight / 2)
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    ScrollView(.vertical) {
        VStack(spacing: .zero) {
            ForEach(0 ..< 5) { _ in
                MarketTokenRowSkeletonView()
            }
        }
    }
}
#endif // DEBUG
