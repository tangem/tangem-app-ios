//
//  TokenMarketsDetailsView+Skeletons.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

extension TokenMarketsDetailsView {
    struct ContentBlockSkeletons: View {
        var body: some View {
            VStack(spacing: 14) {
                description

                portfolio

                insights

                securityScore

                metrics

                pricePerformance

                links
            }
        }

        private var description: some View {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(0 ... 1) { _ in
                    skeletonView(width: .infinity, height: 18)
                }

                skeletonView(width: 270, height: 18)
            }
        }

        private var portfolio: some View {
            VStack(spacing: 10) {
                HStack {
                    Text(Localization.marketsCommonMyPortfolio)
                        .lineLimit(1)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 6) {
                    skeletonView(width: .infinity, height: 15)

                    skeletonView(width: 218, height: 15)
                }
            }
            .defaultRoundedBackground(with: Colors.Background.action)
        }

        private var insights: some View {
            VStack(spacing: .zero) {
                skeletonView(width: .infinity, height: 18)
                    .padding(.bottom, Constants.bottomPaddingTitleConstant)

                ForEach(0 ... 1) { _ in
                    fillableBlocks
                }
            }
            .defaultRoundedBackground(with: Colors.Background.action)
        }

        private var securityScore: some View {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    skeletonView(width: 106, height: 16)

                    skeletonView(width: 106, height: 16)
                }

                Spacer()

                skeletonView(width: 134, height: 20)
            }
            .defaultRoundedBackground(with: Colors.Background.action)
        }

        private var metrics: some View {
            VStack(spacing: .zero) {
                skeletonView(width: .infinity, height: 18)
                    .padding(.bottom, Constants.bottomPaddingTitleConstant)

                ForEach(0 ... 2) { _ in
                    fillableBlocks
                }
            }
            .defaultRoundedBackground(with: Colors.Background.action)
        }

        private var pricePerformance: some View {
            VStack(spacing: 12) {
                skeletonView(width: .infinity, height: 18)
                    .padding(.bottom, Constants.bottomPaddingTitleConstant)

                HStack {
                    skeletonView(width: 28, height: 18)

                    Spacer()

                    skeletonView(width: 38, height: 18)
                }

                skeletonView(width: .infinity, height: 6)

                HStack {
                    skeletonView(width: 60, height: 21)

                    Spacer()

                    skeletonView(width: 60, height: 21)
                }
            }
            .defaultRoundedBackground(with: Colors.Background.action)
        }

        private var links: some View {
            VStack(alignment: .leading, spacing: 12) {
                skeletonView(width: .infinity, height: 18)
                    .padding(.horizontal, 14)
                    .padding(.bottom, Constants.bottomPaddingTitleConstant)

                ForEach(0 ... 2) { index in
                    VStack(alignment: .leading, spacing: 12) {
                        skeletonView(width: 74, height: 18)
                            .padding(.horizontal, 16)

                        HStack(spacing: 12) {
                            ForEach(0 ... 2) { _ in
                                SkeletonView()
                                    .frame(maxWidth: .infinity, minHeight: 28, maxHeight: 28)
                                    .cornerRadiusContinuous(14)
                            }
                        }
                        .padding(.horizontal, 16)

                        if index != 2 {
                            Separator(height: .minimal, color: Colors.Stroke.primary)
                                .padding(.leading, 16)
                        }
                    }
                }
            }
            .defaultRoundedBackground(with: Colors.Background.action, horizontalPadding: 0)
        }

        private var fillableBlocks: some View {
            HStack(spacing: 12) {
                ForEach(0 ... 1) { _ in
                    VStack(alignment: .leading, spacing: 4) {
                        skeletonView(width: .infinity, height: 18)

                        skeletonView(width: 70, height: 21)
                    }
                }
            }
            .padding(.top, 10)
        }

        private func skeletonView(width: CGFloat, height: CGFloat) -> some View {
            SkeletonView()
                .cornerRadiusContinuous(3)
                .frame(maxWidth: width, minHeight: height, maxHeight: height)
        }
    }
}

extension TokenMarketsDetailsView.ContentBlockSkeletons {
    enum Constants {
        static let bottomPaddingTitleConstant: CGFloat = 8
    }
}

#Preview {
    ScrollView {
        TokenMarketsDetailsView.ContentBlockSkeletons()
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
