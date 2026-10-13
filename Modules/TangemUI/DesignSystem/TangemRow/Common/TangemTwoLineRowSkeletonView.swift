//
//  TangemTwoLineRowSkeletonView.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public struct TangemTwoLineRowSkeletonView: View {
    @ScaledMetric private var iconSize: CGFloat = 40
    @ScaledMetric private var horizontalPadding: CGFloat = 16
    @ScaledMetric private var verticalPadding: CGFloat = 12

    @ScaledMetric private var primaryBarHeight: CGFloat = 20
    @ScaledMetric private var primaryLeadingBarWidth: CGFloat = 110
    @ScaledMetric private var primaryTrailingBarWidth: CGFloat = 64

    @ScaledMetric private var secondaryBarHeight: CGFloat = 16
    @ScaledMetric private var secondaryBarWidth: CGFloat = 50

    public init() {}

    public var body: some View {
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
        Shimmer()
            .variant(.custom(width: primaryLeadingBarWidth, height: primaryBarHeight))
    }

    private var primaryTrailingSkeleton: some View {
        Shimmer()
            .variant(.custom(width: primaryTrailingBarWidth, height: primaryBarHeight))
    }

    private var secondaryLeadingSkeleton: some View {
        Shimmer()
            .variant(.custom(width: secondaryBarWidth, height: secondaryBarHeight))
    }

    private var secondaryTrailingSkeleton: some View {
        Shimmer()
            .variant(.custom(width: secondaryBarWidth, height: secondaryBarHeight))
    }
}

// MARK: - Previews

#Preview {
    ScrollView(.vertical) {
        VStack(spacing: .zero) {
            ForEach(0 ..< 5) { _ in
                TangemTwoLineRowSkeletonView()
            }
        }
    }
}
