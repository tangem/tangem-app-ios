//
//  PolymarketPositionRowSkeleton.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

public struct PolymarketPositionsSkeletonView: View {
    private let rowCount: Int

    public init(rowCount: Int) {
        self.rowCount = rowCount
    }

    public var body: some View {
        VStack(spacing: Constants.rowSpacing) {
            ForEach(0 ..< rowCount, id: \.self) { _ in
                PolymarketPositionRowSkeleton()
            }
        }
    }
}

struct PolymarketPositionRowSkeleton: View {
    var body: some View {
        HStack(alignment: .top, spacing: Constants.contentSpacing) {
            VStack(alignment: .leading, spacing: Constants.titleSpacing) {
                bar(width: Constants.titleWidth, height: Constants.titleHeight)
                bar(width: Constants.subtitleWidth, height: Constants.titleHeight)

                HStack(spacing: Constants.footerSpacing) {
                    bar(width: Constants.bubbleWidth, height: Constants.footerHeight)
                    bar(width: Constants.changeWidth, height: Constants.footerHeight)
                }
                .padding(.top, Constants.footerTopPadding)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Shimmer()
                .frame(width: Constants.avatarSide, height: Constants.avatarSide)
                .clipShape(Circle())
        }
        .padding(Constants.padding)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
    }

    private func bar(width: CGFloat, height: CGFloat) -> some View {
        Shimmer()
            .frame(width: width, height: height)
            .clipShape(Capsule())
    }
}

// MARK: - Constants

private extension PolymarketPositionsSkeletonView {
    enum Constants {
        static let rowSpacing: CGFloat = 8
    }
}

private extension PolymarketPositionRowSkeleton {
    enum Constants {
        static let padding: CGFloat = 16
        static let cornerRadius: CGFloat = 24
        static let contentSpacing: CGFloat = 20
        static let titleSpacing: CGFloat = 4
        static let titleWidth: CGFloat = 160
        static let subtitleWidth: CGFloat = 128
        static let titleHeight: CGFloat = 16
        static let footerSpacing: CGFloat = 8
        static let footerTopPadding: CGFloat = 4
        static let footerHeight: CGFloat = 20
        static let bubbleWidth: CGFloat = 48
        static let changeWidth: CGFloat = 96
        static let avatarSide: CGFloat = 40
    }
}

// MARK: - Previews

#Preview {
    PolymarketPositionsSkeletonView(rowCount: 3)
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Color.bgPrimary)
}
