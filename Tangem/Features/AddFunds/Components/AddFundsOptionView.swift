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
    let viewData: ViewData
    let isEnabled: Bool
    let action: () -> Void

    @ScaledMetric(wrappedValue: .unit(.x10)) private var iconContainerSize: CGFloat
    @ScaledMetric(wrappedValue: .unit(.x5)) private var iconSize: CGFloat
    @ScaledMetric(wrappedValue: .unit(.x6)) private var chevronSize: CGFloat
    @ScaledMetric(wrappedValue: .unit(.x4)) private var horizontalPadding: CGFloat
    @ScaledMetric(wrappedValue: .unit(.x3)) private var verticalPadding: CGFloat

    init(viewData: ViewData, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.viewData = viewData
        self.isEnabled = isEnabled
        self.action = action
    }

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
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : Constants.disabledOpacity)
        .accessibilityIdentifier(viewData.accessibilityIdentifier)
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(Color.Tangem.Markers.backgroundTintedBlue)

            viewData.icon.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.Tangem.Markers.iconBlue)
                .frame(width: iconSize, height: iconSize)
        }
        .frame(width: iconContainerSize, height: iconContainerSize)
    }

    private var titleView: some View {
        Text(viewData.title)
            .style(.Tangem.Body16.medium.font, color: .Tangem.Text.Neutral.primary)
            .lineLimit(1)
    }

    private var subtitleView: some View {
        Text(viewData.subtitle)
            .style(.Tangem.Caption12.semibold.font, color: .Tangem.Text.Neutral.primary)
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

// MARK: - Constants

private extension AddFundsOptionView {
    enum Constants {
        static let disabledOpacity: CGFloat = 0.4
    }
}

// MARK: - ViewData

extension AddFundsOptionView {
    struct ViewData {
        let icon: ImageType
        let title: String
        let subtitle: String
        let accessibilityIdentifier: String
    }
}

// MARK: - Add Funds (buy) options

extension AddFundsOptionView {
    init(option: Option, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.init(viewData: option.viewData, isEnabled: isEnabled, action: action)
    }

    @RawCaseName
    enum Option: Identifiable {
        case buy
        case swap
        case receive

        var viewData: ViewData {
            ViewData(
                icon: icon,
                title: title,
                subtitle: subtitle,
                accessibilityIdentifier: accessibilityIdentifier
            )
        }

        private var accessibilityIdentifier: String {
            switch self {
            case .buy: ActionButtonsAccessibilityIdentifiers.addFundsBuyRow
            case .swap: ActionButtonsAccessibilityIdentifiers.addFundsSwapRow
            case .receive: ActionButtonsAccessibilityIdentifiers.addFundsReceiveRow
            }
        }

        private var title: String {
            switch self {
            case .buy: Localization.commonBuy
            case .swap: Localization.commonSwap
            case .receive: Localization.commonReceive
            }
        }

        private var subtitle: String {
            switch self {
            case .buy: Localization.addfundsBuyRowDescription
            case .swap: Localization.addfundsSwapRowDescription
            case .receive: Localization.addfundsReceiveRowDescription
            }
        }

        private var icon: ImageType {
            switch self {
            case .buy: Assets.AddFunds.addfundsBuy
            case .swap: Assets.AddFunds.addfundsSwapIcon
            case .receive: Assets.AddFunds.addfundsReceive
            }
        }
    }
}
