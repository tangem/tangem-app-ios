//
//  MarketsTokenDetailsView+SkeletonsRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

extension MarketsTokenDetailsView {
    struct DescriptionBlockSkeletonsRedesign: View {
        private let lineHeight: CGFloat = .unit(.x4)

        var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                skeletonLine(trailingInset: 0)
                skeletonLine(trailingInset: 0)
                skeletonLine(trailingInset: 72)
            }
        }

        private func skeletonLine(trailingInset: CGFloat) -> some View {
            SkeletonView()
                .cornerRadiusContinuous(lineHeight / 2)
                .frame(maxWidth: .infinity, minHeight: lineHeight, maxHeight: lineHeight)
                .padding(.trailing, trailingInset)
        }
    }

    struct ContentBlockSkeletonsRedesign: View {
        var body: some View {
            VStack(spacing: Constants.blockSpacing) {
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
            VStack(spacing: .unit(.x3)) {
                VStack(spacing: .unit(.x2)) {
                    HStack(spacing: .unit(.x2)) {
                        metricsCard
                        metricsCard
                    }

                    HStack(spacing: .unit(.x2)) {
                        metricsCard
                        metricsCard
                    }
                }

                circulatingSupplyCard
            }
        }

        private var metricsCard: some View {
            VStack(alignment: .leading, spacing: .unit(.x6)) {
                skeletonView(width: .infinity, height: 26)

                skeletonView(width: 82, height: 16)
            }
            .padding(.unit(.x4))
            .background(Color.Tangem.Surface.level3)
            .cornerRadiusContinuous(.unit(.x6))
        }

        private var circulatingSupplyCard: some View {
            VStack(spacing: .unit(.x5)) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: .unit(.x3)) {
                        skeletonView(width: 110, height: 16)
                        skeletonView(width: 160, height: 28)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: .unit(.x3)) {
                        skeletonView(width: 70, height: 16)
                        skeletonView(width: 50, height: 28)
                    }
                }

                skeletonView(width: .infinity, height: .unit(.x1))
            }
            .roundedBackground(
                with: .Tangem.Surface.level3,
                padding: .unit(.x4),
                radius: .unit(.x6)
            )
        }

        // MARK: - Insights

        private var insights: some View {
            VStack(spacing: .unit(.x6)) {
                HStack(spacing: .unit(.x1)) {
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
                    spacing: .unit(.x4)
                ) {
                    ForEach(0 ..< 4, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: .unit(.x1)) {
                            skeletonView(width: 154, height: 24)

                            skeletonView(width: 78, height: 16)
                        }
                    }
                }
            }
            .roundedBackground(
                with: .Tangem.Surface.level3,
                padding: .unit(.x4),
                radius: .unit(.x6)
            )
        }

        // MARK: - Listed on exchanges

        private var listedOnExchanges: some View {
            HStack {
                VStack(alignment: .leading, spacing: .unit(.x1)) {
                    skeletonView(width: 112, height: 24)
                    skeletonView(width: 75, height: 16)
                }

                Spacer()
            }
            .roundedBackground(
                with: .Tangem.Surface.level3,
                padding: .unit(.x4),
                radius: .unit(.x6)
            )
        }

        // MARK: - News

        private var news: some View {
            VStack(alignment: .leading, spacing: .unit(.x3)) {
                skeletonView(width: 120, height: .unit(.x6))
                    .padding(.horizontal, .unit(.x2))

                MarketsCarouselNewsSkeletonView()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, .unit(.x4))
        }

        // MARK: - Security score

        private var securityScore: some View {
            HStack(alignment: .top) {
                makeScoreColumn(alignment: .leading)

                Spacer()

                makeScoreColumn(alignment: .trailing)
            }
            .padding(.vertical, .unit(.x5))
            .padding(.horizontal, .unit(.x4))
            .background(Color.Tangem.Surface.level3)
            .cornerRadiusContinuous(.unit(.x6))
            .padding(.vertical, .unit(.x5))
        }

        private func makeScoreColumn(alignment: HorizontalAlignment) -> some View {
            VStack(alignment: alignment, spacing: .unit(.x2)) {
                skeletonView(width: 115, height: 36)

                skeletonView(width: 84, height: 16)
            }
        }

        // MARK: - Links

        private var links: some View {
            VStack(alignment: .leading, spacing: .unit(.x4)) {
                skeletonView(width: 64, height: 20)
                    .padding(.top, .unit(.x6))

                HStack(spacing: .unit(.x2)) {
                    skeletonView(width: 148, height: 36)
                    skeletonView(width: 110, height: 36)
                }
            }
            .padding(.bottom, .unit(.x2))
        }

        // MARK: - Helpers

        private func skeletonView(width: CGFloat, height: CGFloat) -> some View {
            SkeletonView()
                .cornerRadiusContinuous(height / 2)
                .frame(maxWidth: width, minHeight: height, maxHeight: height)
        }
    }
}

// MARK: - Constants

private extension MarketsTokenDetailsView.ContentBlockSkeletonsRedesign {
    enum Constants {
        static let blockSpacing: CGFloat = .unit(.x2)
        static let metricsCardMinHeight: CGFloat = 120
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    ScrollView {
        VStack(spacing: 16) {
            MarketsTokenDetailsView.DescriptionBlockSkeletonsRedesign()

            MarketsTokenDetailsView.ContentBlockSkeletonsRedesign()
        }
        .padding(.horizontal, .unit(.x4))
    }
    .background(Color.Tangem.Surface.level2.edgesIgnoringSafeArea(.all))
}
#endif // DEBUG
