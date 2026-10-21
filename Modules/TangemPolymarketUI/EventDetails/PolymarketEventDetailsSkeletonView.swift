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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                header

                VStack(spacing: Constants.cardSpacing) {
                    ForEach(0 ..< Constants.cardCount, id: \.self) { _ in
                        PolymarketMarketCard.skeleton
                    }
                }
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.vertical, Constants.marketsVerticalPadding)

                summary
            }
        }
        .scrollDisabled(true)
        .allowsHitTesting(false)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Constants.headerSpacing) {
            VStack(alignment: .leading, spacing: 0) {
                Shimmer().variant(.text(style: .headingMedium))
                Shimmer().variant(.text(style: .headingMedium))
            }

            HStack(spacing: Constants.metaSpacing) {
                bar(width: Constants.badgeWidth, height: Constants.metaLineHeight)
                bar(width: Constants.volumeWidth, height: Constants.metaLineHeight)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Constants.textHorizontalPadding)
        .padding(.vertical, Constants.headerVerticalPadding)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: Constants.summarySpacing) {
            VStack(alignment: .leading, spacing: Constants.descriptionLineSpacing) {
                ForEach(Constants.descriptionLineWidths, id: \.self) { width in
                    bar(width: width, height: Constants.descriptionLineHeight)
                }
            }
            .padding(.horizontal, Constants.textHorizontalPadding)

            VStack(spacing: Constants.infoRowSpacing) {
                ForEach(0 ..< Constants.infoRowCount, id: \.self) { _ in
                    HStack {
                        bar(width: Constants.infoTitleWidth, height: Constants.descriptionLineHeight)

                        Spacer(minLength: 0)

                        bar(width: Constants.infoValueWidth, height: Constants.descriptionLineHeight)
                    }
                }
            }
            .padding(.horizontal, Constants.horizontalPadding)
        }
        .padding(.vertical, Constants.summarySpacing)
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
        static let metaLineHeight: CGFloat = 16
        static let metaSpacing: CGFloat = 8
        static let badgeWidth: CGFloat = 40
        static let volumeWidth: CGFloat = 140

        static let marketsVerticalPadding: CGFloat = 16
        static let cardSpacing: CGFloat = 8
        static let cardCount = 2

        static let summarySpacing: CGFloat = 24
        static let descriptionLineSpacing: CGFloat = 8
        static let descriptionLineHeight: CGFloat = 14
        static let descriptionLineWidths: [CGFloat] = [300, 280, 180]
        static let infoRowSpacing: CGFloat = 20
        static let infoRowCount = 2
        static let infoTitleWidth: CGFloat = 110
        static let infoValueWidth: CGFloat = 140
    }
}

// MARK: - Previews

#Preview {
    PolymarketEventDetailsSkeletonView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
