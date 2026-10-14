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
        VStack(spacing: Constants.rootSpacing) {
            title

            footer
        }
        .padding(Constants.padding)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
    }

    private var title: some View {
        HStack(spacing: Constants.contentSpacing) {
            VStack(alignment: .leading, spacing: Constants.lineSpacing) {
                bar(width: Constants.titleWidth, height: Constants.lineHeight)
                bar(width: Constants.subtitleWidth, height: Constants.lineHeight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Shimmer()
                .frame(width: Constants.avatarSide, height: Constants.avatarSide)
                .clipShape(Circle())
        }
    }

    private var footer: some View {
        HStack(spacing: Constants.footerSpacing) {
            Shimmer().variant(.custom(width: Constants.bubbleWidth, height: Constants.footerHeight))
            Shimmer().variant(.custom(width: Constants.changeWidth, height: Constants.footerHeight))

            Spacer(minLength: Constants.footerSpacing)

            Shimmer().variant(.custom(width: Constants.trailingWidth, height: Constants.footerHeight))
        }
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

/// The row it stands in for is a two-line title beside a 40pt avatar, with the outcome bubble underneath,
/// so the numbers here are the ones `TangemUI.Row` lays that out with.
private extension PolymarketPositionRowSkeleton {
    enum Constants {
        static let padding: CGFloat = 16
        static let cornerRadius: CGFloat = 24
        static let contentSpacing: CGFloat = 12
        static let rootSpacing: CGFloat = 8
        static let lineSpacing: CGFloat = 4
        static let lineHeight: CGFloat = 18
        static let titleWidth: CGFloat = 160
        static let subtitleWidth: CGFloat = 128
        static let footerSpacing: CGFloat = 8
        static let footerHeight: CGFloat = 24
        static let bubbleWidth: CGFloat = 48
        static let changeWidth: CGFloat = 96
        static let trailingWidth: CGFloat = 64
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
