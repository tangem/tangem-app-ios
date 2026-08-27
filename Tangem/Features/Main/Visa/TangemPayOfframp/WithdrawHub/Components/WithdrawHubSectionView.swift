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
    let staticContent: () -> StaticContent
    let dynamicContent: () -> DynamicContent

    private let itemWidth: CGFloat = 156

    init(
        title: String,
        subtitle: String,
        @ViewBuilder staticContent: @escaping () -> StaticContent,
        @ViewBuilder dynamicContent: @escaping () -> DynamicContent
    ) {
        self.title = title
        self.subtitle = subtitle
        self.staticContent = staticContent
        self.dynamicContent = dynamicContent
    }

    var body: some View {
        VStack(spacing: .zero) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)

                Text(subtitle)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    staticContent()
                        .frame(width: itemWidth)

                    // [REDACTED_TODO_COMMENT]
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

// MARK: - Previews

#Preview {
    WithdrawHubSectionView(
        title: "Transfer or swap",
        subtitle: "From your payment account",
        staticContent: {
            WithdrawHubActionTileView(
                icon: DesignSystem.Icons.ArrowSwapHorizontal.regular20,
                title: "Within your portfolio",
                action: {}
            )
        },
        dynamicContent: { EmptyView() }
    )
}
