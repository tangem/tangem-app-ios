//
//  NewsArticleSkeletonView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemUI

struct NewsArticleSkeletonView: View {
    private let contentLineWidths: [CGFloat] = [1.0, 0.78, 0.85, 0.68, 0.80, 1.0]

    var body: some View {
        GeometryReader { geometry in
            RedesignContentView(
                contentWidth: geometry.size.width,
                contentLineWidths: contentLineWidths
            )
        }
    }
}

// MARK: - Redesign

private extension NewsArticleSkeletonView {
    struct RedesignContentView: View {
        let contentWidth: CGFloat
        let contentLineWidths: [CGFloat]

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: .zero) {
                    rateBlockSkeleton
                        .padding(.top, 16)

                    FixedSpacer(height: 20)

                    titleSkeleton

                    FixedSpacer(height: 16)

                    categoryChipsSkeleton

                    FixedSpacer(height: 32)

                    contentSkeletonLines
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .scrollIndicators(.hidden)
        }

        private var rateBlockSkeleton: some View {
            HStack(spacing: 30) {
                rateColumnSkeleton(titleWidth: 70, subtitleWidth: 110)

                Rectangle()
                    .fill(DesignSystem.Color.borderSecondary)
                    .frame(width: 1, height: 45)

                rateColumnSkeleton(titleWidth: 50, subtitleWidth: 120)
            }
        }

        private func rateColumnSkeleton(titleWidth: CGFloat, subtitleWidth: CGFloat) -> some View {
            VStack(alignment: .leading, spacing: 10) {
                Shimmer()
                    .variant(.custom(width: titleWidth, height: 16, cornerRadius: 8))

                Shimmer()
                    .variant(.custom(width: subtitleWidth, height: 16, cornerRadius: 8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        private var titleSkeleton: some View {
            VStack(alignment: .leading, spacing: 12) {
                Shimmer()
                    .variant(.custom(height: 32, cornerRadius: 16))
                    .frame(maxWidth: .infinity)

                Shimmer()
                    .variant(.custom(width: (contentWidth - 32) * 0.6, height: 32, cornerRadius: 16))
            }
        }

        private var categoryChipsSkeleton: some View {
            HStack(spacing: 4) {
                Shimmer()
                    .variant(.custom(width: 82, height: 32, cornerRadius: 16))

                Shimmer()
                    .variant(.custom(width: 66, height: 32, cornerRadius: 16))
            }
        }

        private var contentSkeletonLines: some View {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0 ..< contentLineWidths.count, id: \.self) { index in
                    Shimmer()
                        .variant(.custom(
                            width: (contentWidth - 32) * contentLineWidths[index],
                            height: 16,
                            cornerRadius: 8
                        ))
                }
            }
        }
    }
}
