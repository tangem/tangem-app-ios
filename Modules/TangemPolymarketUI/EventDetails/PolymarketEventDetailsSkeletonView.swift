//
//  PolymarketEventDetailsSkeletonView.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

public struct PolymarketEventDetailsSkeletonView: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header

                VStack(spacing: Constants.cardSpacing) {
                    ForEach(0 ..< Constants.cardCount, id: \.self) { _ in
                        PolymarketMarketCard.skeleton
                    }
                }
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.vertical, Constants.marketsVerticalPadding)
            }
        }
        .scrollDisabled(true)
        .allowsHitTesting(false)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Constants.headerSpacing) {
            bar(width: Constants.titleFirstLineWidth, height: Constants.titleLineHeight)
            bar(width: Constants.titleSecondLineWidth, height: Constants.titleLineHeight)

            HStack(spacing: Constants.metaSpacing) {
                bar(width: Constants.badgeWidth, height: Constants.metaLineHeight)
                bar(width: Constants.volumeWidth, height: Constants.metaLineHeight)
            }
            .padding(.top, Constants.metaTopPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Constants.textHorizontalPadding)
        .padding(.vertical, Constants.headerVerticalPadding)
    }

    private func bar(width: CGFloat, height: CGFloat) -> some View {
        Shimmer()
            .frame(width: width, height: height)
            .clipShape(Capsule())
    }
}

// MARK: - Constants

private extension PolymarketEventDetailsSkeletonView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let textHorizontalPadding: CGFloat = 20

        static let headerSpacing: CGFloat = 8
        static let headerVerticalPadding: CGFloat = 16
        static let titleLineHeight: CGFloat = 34
        static let titleFirstLineWidth: CGFloat = 300
        static let titleSecondLineWidth: CGFloat = 220
        static let metaLineHeight: CGFloat = 16
        static let metaSpacing: CGFloat = 8
        static let metaTopPadding: CGFloat = 4
        static let badgeWidth: CGFloat = 40
        static let volumeWidth: CGFloat = 140

        static let marketsVerticalPadding: CGFloat = 16
        static let cardSpacing: CGFloat = 8
        static let cardCount = 7
    }
}

// MARK: - Previews

#Preview {
    PolymarketEventDetailsSkeletonView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
