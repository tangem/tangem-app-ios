//
//  FeedWidgetSkeletonView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct FeedWidgetSkeletonView: View {
    @ScaledMetric private var accessorySide: CGFloat = Constants.accessorySide

    var body: some View {
        FeedProductCardLayout {
            HStack(alignment: .top, spacing: 0) {
                Shimmer()
                    .variant(.custom(width: Constants.tileSide, height: Constants.tileSide, cornerRadius: Constants.tileCornerRadius))

                Spacer(minLength: 0)

                Circle()
                    .fill(DesignSystem.Color.bgOpaquePrimary)
                    .frame(size: CGSize(bothDimensions: accessorySide))
                    .offset(x: Constants.accessoryOffset, y: -Constants.accessoryOffset)
            }
        } content: {
            VStack(alignment: .leading, spacing: 0) {
                Shimmer().variant(.text(style: .caption))
                Shimmer().variant(.text(style: .subheading))
                Shimmer().variant(.text(style: .subheading))
            }
        } background: {
            FeedWidgetBackground(defaultColor: DesignSystem.Color.bgSecondary)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Constants

private extension FeedWidgetSkeletonView {
    enum Constants {
        static let tileSide: CGFloat = 40
        static let tileCornerRadius: CGFloat = 12
        static let accessorySide: CGFloat = 24
        static let accessoryOffset: CGFloat = 4
    }
}
