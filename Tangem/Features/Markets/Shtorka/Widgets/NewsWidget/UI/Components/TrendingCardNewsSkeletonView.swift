//
//  TrendingCardNewsSkeletonView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TrendingCardNewsSkeletonView: View {
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
        .frame(maxWidth: .infinity, alignment: .leading)
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
            ForEach(0 ..< 3, id: \.self) { _ in
                Shimmer()
                    .variant(.custom(width: 63, height: 24))
            }
        }
    }
}

// MARK: - Previews

#Preview {
    TrendingCardNewsSkeletonView()
        .padding()
}
