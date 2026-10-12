//
//  FeedProductCardView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

struct FeedProductCardView: View {
    let caption: String
    let message: String
    let appearance: Appearance

    @ScaledMetric private var accessorySide: CGFloat = Constants.accessorySide
    @ScaledMetric private var accessoryIconSide: CGFloat = Constants.accessoryIconSide

    var body: some View {
        FeedProductCardLayout {
            HStack(alignment: .top, spacing: 0) {
                FeedProductIconView(appearance: appearance)

                Spacer(minLength: 0)

                accessory
                    .offset(x: Constants.accessoryOffset, y: -Constants.accessoryOffset)
            }
        } content: {
            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(caption)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(message)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
            }
        } background: {
            FeedWidgetBackground(defaultColor: DesignSystem.Color.bgTransparentPrimary)
                .overlay { FeedProductGlowView(color: appearance.color) }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Subviews

private extension FeedProductCardView {
    var accessory: some View {
        DesignSystem.Icons.SignPlus.regular16.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(size: CGSize(bothDimensions: accessoryIconSide))
            .foregroundStyle(DesignSystem.Color.iconSecondary)
            .frame(size: CGSize(bothDimensions: accessorySide))
            .background(DesignSystem.Color.bgTransparentPrimary, in: Circle())
            .accessibilityHidden(true)
    }
}

// MARK: - Constants

private extension FeedProductCardView {
    enum Constants {
        static let textSpacing: CGFloat = 2
        static let accessorySide: CGFloat = 24
        static let accessoryIconSide: CGFloat = 16
        static let accessoryOffset: CGFloat = 4
    }
}
