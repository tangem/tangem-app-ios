//
//  MarketsTokenDetailsView+Skeletons.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

extension MarketsTokenDetailsView {
    struct DescriptionBlockSkeletons: View {
        private let lineHeight: CGFloat = 16

        var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                skeletonLine(trailingInset: 0)
                skeletonLine(trailingInset: 0)
                skeletonLine(trailingInset: 72)
            }
        }

        private func skeletonLine(trailingInset: CGFloat) -> some View {
            Shimmer()
                .variant(.custom(height: lineHeight))
                .frame(maxWidth: .infinity)
                .padding(.trailing, trailingInset)
        }
    }

    struct ContentBlockSkeletons: View {
        var body: some View {
            VStack(spacing: Constants.blockSpacing) {
                MarketsTokenSummaryPlaceholderView()

                metrics

                insights

                listedOnExchanges

                news

                securityScore

                links
            }
        }

        // MARK: - Metrics

        private var metrics: some View {
            VStack(spacing: 12) {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        metricsCard
                        metricsCard
                    }

                    HStack(spacing: 8) {
                        metricsCard
                        metricsCard
                    }
                }

                circulatingSupplyCard
            }
        }

        private var metricsCard: some View {
            VStack(alignment: .leading, spacing: 24) {
                skeletonView(width: .infinity, height: 26)

                skeletonView(width: 82, height: 16)
            }
            .padding(16)
            .background(DesignSystem.Color.bgSecondary)
            .cornerRadiusContinuous(24)
        }

        private var circulatingSupplyCard: some View {
            VStack(spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 12) {
                        skeletonView(width: 110, height: 16)
                        skeletonView(width: 160, height: 28)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 12) {
                        skeletonView(width: 70, height: 16)
                        skeletonView(width: 50, height: 28)
                    }
                }

                skeletonView(width: .infinity, height: 4)
            }
            .roundedBackground(
                with: DesignSystem.Color.bgSecondary,
                padding: 16,
                radius: 24
            )
        }

        // MARK: - Insights

        private var insights: some View {
            VStack(spacing: 24) {
                HStack(spacing: 4) {
                    skeletonView(width: 112, height: 24)

                    Spacer()

                    skeletonView(width: 156, height: 36)
                }

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), alignment: .topLeading),
                        GridItem(.flexible(), alignment: .topLeading),
                    ],
                    alignment: .leading,
                    spacing: 16
                ) {
                    ForEach(0 ..< 4, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 4) {
                            skeletonView(width: 154, height: 24)

                            skeletonView(width: 78, height: 16)
                        }
                    }
                }
            }
            .roundedBackground(
                with: DesignSystem.Color.bgSecondary,
                padding: 16,
                radius: 24
            )
        }

        // MARK: - Listed on exchanges

        private var listedOnExchanges: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    skeletonView(width: 112, height: 24)
                    skeletonView(width: 75, height: 16)
                }

                Spacer()
            }
            .roundedBackground(
                with: DesignSystem.Color.bgSecondary,
                padding: 16,
                radius: 24
            )
        }

        // MARK: - News

        private var news: some View {
            VStack(alignment: .leading, spacing: 12) {
                skeletonView(width: 120, height: 24)
                    .padding(.horizontal, 8)

                MarketsCarouselNewsSkeletonView()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 16)
        }

        // MARK: - Security score

        private var securityScore: some View {
            HStack(alignment: .top) {
                makeScoreColumn(alignment: .leading)

                Spacer()

                makeScoreColumn(alignment: .trailing)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .background(DesignSystem.Color.bgSecondary)
            .cornerRadiusContinuous(24)
            .padding(.vertical, 20)
        }

        private func makeScoreColumn(alignment: HorizontalAlignment) -> some View {
            VStack(alignment: alignment, spacing: 8) {
                skeletonView(width: 115, height: 36)

                skeletonView(width: 84, height: 16)
            }
        }

        // MARK: - Links

        private var links: some View {
            VStack(alignment: .leading, spacing: 16) {
                skeletonView(width: 64, height: 20)
                    .padding(.top, 24)

                HStack(spacing: 8) {
                    skeletonView(width: 148, height: 36)
                    skeletonView(width: 110, height: 36)
                }
            }
            .padding(.bottom, 8)
        }

        // MARK: - Helpers

        private func skeletonView(width: CGFloat, height: CGFloat) -> some View {
            Shimmer()
                .variant(.custom(height: height))
                .frame(idealWidth: width == .infinity ? nil : width, maxWidth: width)
        }
    }
}

// MARK: - Constants

private extension MarketsTokenDetailsView.ContentBlockSkeletons {
    enum Constants {
        static let blockSpacing: CGFloat = 8
    }
}

// MARK: - Previews

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            MarketsTokenDetailsView.DescriptionBlockSkeletons()

            MarketsTokenDetailsView.ContentBlockSkeletons()
        }
        .padding(.horizontal, 16)
    }
    .background(DesignSystem.Color.bgPrimary.edgesIgnoringSafeArea(.all))
}
