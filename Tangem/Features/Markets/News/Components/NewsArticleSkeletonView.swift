//
//  NewsArticleSkeletonView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemUI

struct NewsArticleSkeletonView: View {
    private let contentLineWidths: [CGFloat] = [1.0, 0.78, 0.85, 0.68, 0.80, 1.0]

    var body: some View {
        if FeatureProvider.isAvailable(.redesign) {
            GeometryReader { geometry in
                RedesignContentView(
                    contentWidth: geometry.size.width,
                    contentLineWidths: contentLineWidths
                )
            }
        } else {
            GeometryReader { geometry in
                ContentView(
                    contentWidth: geometry.size.width,
                    contentLineWidths: contentLineWidths
                )
            }
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
                        .padding(.top, .unit(.x4))

                    FixedSpacer(height: .unit(.x5))

                    titleSkeleton

                    FixedSpacer(height: .unit(.x4))

                    categoryChipsSkeleton

                    FixedSpacer(height: .unit(.x8))

                    contentSkeletonLines
                }
                .padding(.horizontal, .unit(.x4))
                .padding(.top, .unit(.x4))
            }
            .scrollIndicators(.hidden)
        }

        private var rateBlockSkeleton: some View {
            HStack(spacing: 30) {
                rateColumnSkeleton(titleWidth: 70, subtitleWidth: 110)

                Rectangle()
                    .fill(Color.Tangem.Border.Neutral.primary)
                    .frame(width: 1, height: 45)

                rateColumnSkeleton(titleWidth: 50, subtitleWidth: 120)
            }
        }

        private func rateColumnSkeleton(titleWidth: CGFloat, subtitleWidth: CGFloat) -> some View {
            VStack(alignment: .leading, spacing: 10) {
                SkeletonView()
                    .frame(width: titleWidth, height: 16)
                    .cornerRadius(8)

                SkeletonView()
                    .frame(width: subtitleWidth, height: 16)
                    .cornerRadius(8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        private var titleSkeleton: some View {
            VStack(alignment: .leading, spacing: .unit(.x3)) {
                SkeletonView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .cornerRadius(16)

                SkeletonView()
                    .frame(width: (contentWidth - 32) * 0.6, height: 32)
                    .cornerRadius(16)
            }
        }

        private var categoryChipsSkeleton: some View {
            HStack(spacing: .unit(.x1)) {
                SkeletonView()
                    .frame(width: 82, height: 32)
                    .cornerRadius(16)

                SkeletonView()
                    .frame(width: 66, height: 32)
                    .cornerRadius(16)
            }
        }

        private var contentSkeletonLines: some View {
            VStack(alignment: .leading, spacing: .unit(.x2)) {
                ForEach(0 ..< contentLineWidths.count, id: \.self) { index in
                    SkeletonView()
                        .frame(
                            width: (contentWidth - 32) * contentLineWidths[index],
                            height: 16
                        )
                        .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Legacy

private extension NewsArticleSkeletonView {
    struct ContentView: View {
        let contentWidth: CGFloat
        let contentLineWidths: [CGFloat]

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: .zero) {
                    dateSkeleton

                    titleSkeleton

                    tagSkeleton

                    contentSkeletonLines
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .scrollIndicators(.hidden)
        }

        private var dateSkeleton: some View {
            SkeletonView()
                .frame(width: 150, height: 16)
                .cornerRadius(4)
        }

        private var titleSkeleton: some View {
            VStack(alignment: .leading, spacing: 0) {
                SkeletonView()
                    .frame(width: contentWidth * 0.9 - 32, height: 24)
                    .cornerRadius(6)
                    .padding(.top, 12)

                SkeletonView()
                    .frame(width: contentWidth * 0.55 - 32, height: 24)
                    .cornerRadius(6)
                    .padding(.top, 8)
            }
        }

        private var tagSkeleton: some View {
            SkeletonView()
                .frame(width: 100, height: 32)
                .cornerRadius(16)
                .padding(.top, 16)
        }

        private var contentSkeletonLines: some View {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0 ..< contentLineWidths.count, id: \.self) { index in
                    SkeletonView()
                        .frame(
                            width: (contentWidth - 32) * contentLineWidths[index],
                            height: 16
                        )
                        .cornerRadius(4)
                }
            }
            .padding(.top, 32)
        }
    }
}
