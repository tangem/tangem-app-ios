//
//  PolymarketActivityRowSkeleton.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

public struct PolymarketActivitySkeletonView: View {
    private let rowCount: Int

    public init(rowCount: Int) {
        self.rowCount = rowCount
    }

    public var body: some View {
        VStack(spacing: 0) {
            PolymarketActivitySectionHeaderSkeleton()

            ForEach(0 ..< rowCount, id: \.self) { _ in
                PolymarketActivityRowSkeleton()
            }
        }
    }
}

struct PolymarketActivityRowSkeleton: View {
    var body: some View {
        HStack(spacing: Constants.contentSpacing) {
            Shimmer()
                .frame(width: Constants.iconSide, height: Constants.iconSide)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: Constants.lineSpacing) {
                bar(width: Constants.titleWidth, height: Constants.titleHeight)
                bar(width: Constants.subtitleWidth, height: Constants.subtitleHeight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            bar(width: Constants.amountWidth, height: Constants.titleHeight)
        }
        .padding(Constants.padding)
    }

    private func bar(width: CGFloat, height: CGFloat) -> some View {
        Shimmer()
            .frame(width: width, height: height)
            .clipShape(Capsule())
    }
}

struct PolymarketActivitySectionHeaderSkeleton: View {
    var body: some View {
        PolymarketActivitySectionHeader(title: " ")
            .overlay(alignment: .leading) {
                Shimmer()
                    .frame(width: Constants.headerWidth, height: Constants.headerHeight)
                    .clipShape(Capsule())
                    .padding(.leading, Constants.padding)
                    .padding(.top, Constants.headerTopPadding - Constants.headerBottomPadding)
            }
            .accessibilityHidden(true)
    }
}

// MARK: - Constants

private extension PolymarketActivitySectionHeaderSkeleton {
    enum Constants {
        static let padding: CGFloat = 16
        static let headerWidth: CGFloat = 88
        static let headerHeight: CGFloat = 12
        static let headerTopPadding: CGFloat = 24
        static let headerBottomPadding: CGFloat = 12
    }
}

private extension PolymarketActivityRowSkeleton {
    enum Constants {
        static let padding: CGFloat = 16
        static let contentSpacing: CGFloat = 8
        static let lineSpacing: CGFloat = 4
        static let iconSide: CGFloat = 40
        static let titleWidth: CGFloat = 96
        static let titleHeight: CGFloat = 20
        static let subtitleWidth: CGFloat = 144
        static let subtitleHeight: CGFloat = 16
        static let amountWidth: CGFloat = 72
    }
}

// MARK: - Previews

#Preview {
    PolymarketActivitySkeletonView(rowCount: 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(DesignSystem.Color.bgPrimary)
}
