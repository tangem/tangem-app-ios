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

    @ScaledMetric(wrappedValue: .unit(.x10)) private var iconContainerSize: CGFloat
    @ScaledMetric(wrappedValue: .unit(.x5)) private var iconSize: CGFloat
    @ScaledMetric(wrappedValue: .unit(.x6)) private var chevronSize: CGFloat
    @ScaledMetric(wrappedValue: .unit(.x4)) private var horizontalPadding: CGFloat
    @ScaledMetric(wrappedValue: .unit(.x3)) private var verticalPadding: CGFloat

    private var subtitleColor: Color {
        item.isAvailable ? .Tangem.Text.Neutral.secondary : .Tangem.Text.Status.disabled
    }

    private var chevronColor: Color {
        item.isAvailable ? .Tangem.Graphic.Neutral.secondary : .Tangem.Graphic.Neutral.quaternary
    }

    var body: some View {
        // An unavailable row stays tappable so `item.action` can surface the reason alert; dimming is cosmetic.
        Button(action: item.action) {
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
            .background(Color.Tangem.Surface.level3)
            .cornerRadiusContinuous(.unit(.x5))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(item.accessibilityIdentifier)
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(Color.Tangem.Markers.backgroundTintedBlue)

            item.icon.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.Tangem.Markers.iconBlue)
                .frame(width: iconSize, height: iconSize)
        }
        .frame(width: iconContainerSize, height: iconContainerSize)
        .actionControlDimmed(isEnabled: item.isAvailable)
    }

    private var titleView: some View {
        Text(item.title)
            .style(
                Font.Tangem.Body16.medium,
                color: ActionControlAppearance.contentColor(isEnabled: item.isAvailable)
            )
            .lineLimit(1)
    }

    @ViewBuilder
    private var subtitleView: some View {
        if let subtitle = item.subtitle {
            Text(subtitle)
                .style(Font.Tangem.Caption12.semibold, color: subtitleColor)
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
