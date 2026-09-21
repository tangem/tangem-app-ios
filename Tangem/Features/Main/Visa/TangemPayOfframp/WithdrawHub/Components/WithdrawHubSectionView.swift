//
//  WithdrawHubSectionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct WithdrawHubSectionView<StaticContent, DynamicContent>: View
    where StaticContent: View, DynamicContent: View {
    let title: String
    let subtitle: String
    let subtitleColor: Color
    let staticContent: () -> StaticContent
    let dynamicContent: () -> DynamicContent

    @ScaledMetric private var itemWidth: CGFloat = Constants.itemWidth
    @ScaledMetric private var itemHeight: CGFloat = Constants.itemHeight

    init(
        title: String,
        subtitle: String,
        subtitleColor: Color = DesignSystem.Color.textSecondary,
        @ViewBuilder staticContent: @escaping () -> StaticContent,
        @ViewBuilder dynamicContent: @escaping () -> DynamicContent
    ) {
        self.title = title
        self.subtitle = subtitle
        self.subtitleColor = subtitleColor
        self.staticContent = staticContent
        self.dynamicContent = dynamicContent
    }

    var body: some View {
        VStack(spacing: .zero) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)

                Text(subtitle)
                    .style(DesignSystem.Font.captionMediumToken, color: subtitleColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)

            ScrollView(.horizontal) {
                HStack(spacing: Constants.itemSpacing) {
                    staticContent()
                        .frame(width: itemWidth, height: itemHeight)

                    dynamicContent()
                        .frame(width: itemWidth, height: itemHeight)
                }
                .padding(.top, 4)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let itemWidth: CGFloat = 162
    static let itemHeight: CGFloat = 136
    static let itemSpacing: CGFloat = 8
}

// MARK: - Previews

#Preview {
    WithdrawHubSectionView(
        title: "Transfer or swap",
        subtitle: "From your payment account",
        staticContent: {
            WithdrawHubActionTileView(
                data: .action(
                    icon: DesignSystem.Icons.ArrowSwapHorizontal.regular20,
                    title: "Within your portfolio",
                    action: {}
                )
            )
        },
        dynamicContent: {
            WithdrawHubActionTileView(
                data: .placeholder(
                    icon: DesignSystem.Icons.Clock.regular20,
                    title: "Recent transfers appear here"
                )
            )
        }
    )
}
