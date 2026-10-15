//
//  TokenDetailsActionRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct TokenDetailsActionRowView: View {
    let item: TokenDetailsActionRowItem

    @ScaledMetric private var iconContainerSize: CGFloat = 40
    @ScaledMetric private var iconSize: CGFloat = 20
    @ScaledMetric private var chevronSize: CGFloat = 24
    @ScaledMetric private var horizontalPadding: CGFloat = 16
    @ScaledMetric private var verticalPadding: CGFloat = 12

    private var subtitleColor: Color {
        item.isAvailable ? DesignSystem.Color.textSecondary : DesignSystem.Color.textTertiary
    }

    private var chevronColor: Color {
        item.isAvailable ? DesignSystem.Color.iconSecondary : DesignSystem.Color.iconTertiary
    }

    var body: some View {
        SwiftUI.Button(action: item.action) {
            TangemTwoLineRowLayout(
                icon: { iconView },
                primaryLeading: { titleView },
                secondaryLeading: { subtitleView },
                centeredTrailing: { chevronView }
            )
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .background(DesignSystem.Color.bgSecondary)
            .cornerRadiusContinuous(20)
        }
        .buttonStyle(.plain)
        .disabled(!item.isAvailable)
        .accessibilityIdentifier(item.accessibilityIdentifier)
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(DesignSystem.Color.bgStatusInfoSubtle)

            item.icon.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(DesignSystem.Color.iconAccentBlue)
                .frame(width: iconSize, height: iconSize)
        }
        .frame(width: iconContainerSize, height: iconContainerSize)
        .actionControlDimmed(isEnabled: item.isAvailable)
    }

    private var titleView: some View {
        Text(item.title)
            .style(
                DesignSystem.Font.bodyMediumToken,
                color: ActionControlAppearance.contentColor(isEnabled: item.isAvailable)
            )
            .lineLimit(1)
    }

    @ViewBuilder
    private var subtitleView: some View {
        if let subtitle = item.subtitle {
            Text(subtitle)
                .style(DesignSystem.Font.captionMediumToken, color: subtitleColor)
                .lineLimit(1)
        } else {
            EmptyView()
        }
    }

    private var chevronView: some View {
        Assets.chevronRight.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(chevronColor)
            .frame(width: chevronSize, height: chevronSize)
    }
}
