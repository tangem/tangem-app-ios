//
//  FeedWidgetLoadErrorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUIUtils

struct FeedWidgetLoadErrorView: View {
    @ScaledMetric private var iconBackgroundSide: CGFloat = Constants.iconBackgroundSide
    @ScaledMetric private var iconSide: CGFloat = Constants.iconSide

    var body: some View {
        FeedProductCardLayout {
            icon
        } content: {
            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(Localization.feedPromoLoadErrorTitle)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)

                Text(Localization.feedPromoLoadErrorAction)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
            }
        } background: {
            FeedWidgetBackground(defaultColor: DesignSystem.Color.bgSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Subviews

private extension FeedWidgetLoadErrorView {
    var icon: some View {
        DesignSystem.Icons.ArrowRefresh.regular20.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(DesignSystem.Color.iconInverse)
            .frame(size: CGSize(bothDimensions: iconSide))
            .frame(size: CGSize(bothDimensions: iconBackgroundSide))
            .background(DesignSystem.Color.bgInverse, in: Circle())
            .accessibilityHidden(true)
    }
}

// MARK: - Constants

private extension FeedWidgetLoadErrorView {
    enum Constants {
        static let textSpacing: CGFloat = 2
        static let iconBackgroundSide: CGFloat = 40
        static let iconSide: CGFloat = 20
    }
}
