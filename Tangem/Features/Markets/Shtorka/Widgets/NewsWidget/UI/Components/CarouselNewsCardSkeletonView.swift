//
//  CarouselNewsCardSkeletonView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct CarouselNewsCardSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            ratingSkeleton

            FixedSpacer(height: 8)

            titleSkeleton

            FixedSpacer(height: 44)

            timeAgoSkeleton

            FixedSpacer(height: 12)

            tagsSkeleton
        }
        .padding(.all, 16)
        .background(DesignSystem.Color.bgSecondary)
        .cornerRadiusContinuous(24)
    }

    // MARK: - Subviews

    private var ratingSkeleton: some View {
        Shimmer()
            .variant(.custom(width: 50, height: 16))
    }

    private var titleSkeleton: some View {
        Shimmer()
            .variant(.custom(height: 16))
            .frame(maxWidth: .infinity)
    }

    private var timeAgoSkeleton: some View {
        Shimmer()
            .variant(.custom(width: 50, height: 16))
    }

    private var tagsSkeleton: some View {
        HStack(spacing: 8) {
            Shimmer()
                .variant(.custom(width: 78, height: 24))

            Shimmer()
                .variant(.custom(width: 65, height: 24))

            Shimmer()
                .variant(.custom(width: 32, height: 24))
        }
    }
}

// MARK: - Previews

#Preview {
    HStack(spacing: 12) {
        CarouselNewsCardSkeletonView()
        CarouselNewsCardSkeletonView()
    }
    .padding()
}
