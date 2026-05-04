//
//  CarouselNewsCardSkeletonView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct CarouselNewsCardSkeletonView: View {
    @ScaledMetric private var barHeight: CGFloat = 16
    @ScaledMetric private var smallBarWidth: CGFloat = 50
    @ScaledMetric private var tagHeight: CGFloat = 24
    @ScaledMetric private var tagWidth1: CGFloat = 78
    @ScaledMetric private var tagWidth2: CGFloat = 65
    @ScaledMetric private var tagWidth3: CGFloat = 32

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
        .padding(.all, .unit(.x4))
        .background(Color.Tangem.Surface.level3)
        .cornerRadiusContinuous(.unit(.x5))
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
            SkeletonView()
                .frame(width: tagWidth1, height: tagHeight)
                .cornerRadius(tagHeight / 2)

            SkeletonView()
                .frame(width: tagWidth2, height: tagHeight)
                .cornerRadius(tagHeight / 2)

            SkeletonView()
                .frame(width: tagWidth3, height: tagHeight)
                .cornerRadius(tagHeight / 2)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    HStack(spacing: .unit(.x3)) {
        CarouselNewsCardSkeletonView()
        CarouselNewsCardSkeletonView()
    }
    .padding()
}
#endif // DEBUG
