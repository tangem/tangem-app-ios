//
//  AddFundsOptionView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization
import TangemMacro
import TangemUI
import TangemUIUtils

struct AddFundsOptionView: View {
    let option: Option
    let action: () -> Void

    @ScaledMetric(wrappedValue: .unit(.x10)) private var iconContainerSize: CGFloat
    @ScaledMetric(wrappedValue: .unit(.x5)) private var iconSize: CGFloat
    @ScaledMetric(wrappedValue: .unit(.x6)) private var chevronSize: CGFloat
    @ScaledMetric(wrappedValue: .unit(.x4)) private var horizontalPadding: CGFloat
    @ScaledMetric(wrappedValue: .unit(.x3)) private var verticalPadding: CGFloat

    var body: some View {
        Button(action: action) {
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
        .accessibilityIdentifier(option.accessibilityIdentifier)
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(Color.Tangem.Markers.backgroundTintedBlue)

            option.icon.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.Tangem.Markers.iconBlue)
                .frame(width: iconSize, height: iconSize)
        }
        .frame(width: iconContainerSize, height: iconContainerSize)
    }

    private var titleView: some View {
        Text(option.title)
            .style(.Tangem.Body16.medium, color: .Tangem.Text.Neutral.primary)
            .lineLimit(1)
    }

    private var subtitleView: some View {
        Text(option.subtitle)
            .style(.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.secondary)
            .lineLimit(1)
    }

    private var chevronView: some View {
        Assets.chevronRight.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.Tangem.Graphic.Neutral.secondary)
            .frame(width: chevronSize, height: chevronSize)
    }
}

extension AddFundsOptionView {
    @RawCaseName
    enum Option: Identifiable {
        case buy
        case swap
        case receive

        var accessibilityIdentifier: String {
            switch self {
            case .buy:
                ActionButtonsAccessibilityIdentifiers.addFundsBuyRow
            case .swap:
                ActionButtonsAccessibilityIdentifiers.addFundsSwapRow
            case .receive:
                ActionButtonsAccessibilityIdentifiers.addFundsReceiveRow
            }
        }

        var title: String {
            switch self {
            case .buy: Localization.commonBuy
            case .swap: Localization.commonSwap
            case .receive: Localization.commonReceive
            }
        }

        var subtitle: String {
            switch self {
            case .buy: Localization.addfundsBuyRowDescription
            case .swap: Localization.addfundsSwapRowDescription
            case .receive: Localization.addfundsReceiveRowDescription
            }
        }

        var icon: ImageType {
            switch self {
            case .buy: Assets.AddFunds.addfundsBuy
            case .swap: Assets.AddFunds.addfundsSwapIcon
            case .receive: Assets.AddFunds.addfundsReceive
            }
        }
    }
}
