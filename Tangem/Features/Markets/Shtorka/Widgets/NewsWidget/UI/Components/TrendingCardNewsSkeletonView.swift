//
//  TrendingCardNewsSkeletonView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct TrendingCardNewsSkeletonView: View {
    @ScaledMetric private var barHeight: CGFloat = 16
    @ScaledMetric private var smallBarWidth: CGFloat = 50
    @ScaledMetric private var tagHeight: CGFloat = 24
    @ScaledMetric private var tagWidth: CGFloat = 63

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            ratingSkeleton

            FixedSpacer(height: .unit(.x2))

            titleSkeleton

            FixedSpacer(height: .unit(.x11))

            timeAgoSkeleton

            FixedSpacer(height: .unit(.x3))

            tagsSkeleton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.all, .unit(.x4))
        .background(Color.Tangem.Surface.level3)
        .cornerRadiusContinuous(.unit(.x6))
    }

    // MARK: - Subviews

    private var ratingSkeleton: some View {
        SkeletonView()
            .frame(width: smallBarWidth, height: barHeight)
            .cornerRadius(barHeight / 2)
    }

    private var titleSkeleton: some View {
        SkeletonView()
            .frame(maxWidth: .infinity)
            .frame(height: barHeight)
            .cornerRadius(barHeight / 2)
    }

    private var timeAgoSkeleton: some View {
        SkeletonView()
            .frame(width: smallBarWidth, height: barHeight)
            .cornerRadius(barHeight / 2)
    }

    private var tagsSkeleton: some View {
        HStack(spacing: .unit(.x2)) {
            ForEach(0 ..< 3, id: \.self) { _ in
                SkeletonView()
                    .frame(width: tagWidth, height: tagHeight)
                    .cornerRadius(tagHeight / 2)
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    TrendingCardNewsSkeletonView()
        .padding()
}
#endif // DEBUG
