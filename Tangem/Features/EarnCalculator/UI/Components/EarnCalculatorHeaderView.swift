//
//  EarnCalculatorHeaderView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemUI
import TangemUIUtils

struct EarnCalculatorHeaderView: View {
    let incentiveBadgeText: String?
    let totalBalance: String
    let earned: String
    let horizonTitle: String
    let horizons: [EarnCalculatorHorizon]
    @Binding var selectedHorizon: EarnCalculatorHorizon
    let onIncentiveInfoTap: (() -> Void)?

    var body: some View {
        VStack(spacing: Constants.spacing) {
            incentiveBadge

            Text(totalBalance)
                .style(DesignSystem.Font.displayMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(Constants.totalBalanceMinimumScaleFactor)
                .accessibilityIdentifier(EarnCalculatorAccessibilityIdentifiers.totalBalance)

            horizonMenu
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Subviews

private extension EarnCalculatorHeaderView {
    @ViewBuilder
    var incentiveBadge: some View {
        if let incentiveBadgeText {
            let badge = Badge(label: incentiveBadgeText, accessibilityLabel: nil)
                .size(.x6)
                .variant(.tinted)
                .appearance(.info)

            if let onIncentiveInfoTap {
                SwiftUI.Button(action: onIncentiveInfoTap) {
                    badge.slotEnd(DesignSystem.Icons.Info.regular16)
                }
                .buttonStyle(.plain)
            } else {
                badge
            }
        }
    }

    var horizonMenu: some View {
        Menu {
            Picker(selection: $selectedHorizon) {
                ForEach(horizons, id: \.self) { horizon in
                    Text(horizon.menuTitle).tag(horizon)
                }
            } label: {
                EmptyView()
            }
        } label: {
            HStack(spacing: Constants.menuLabelSpacing) {
                Text(earnedLine)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)

                DesignSystem.Icons.ChevronDoubleVertical.regular16.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconPrimary)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityIdentifier(EarnCalculatorAccessibilityIdentifiers.horizonMenu)
    }

    var earnedLine: AttributedString {
        // [REDACTED_TODO_COMMENT]
        var line = AttributedString("\(earned) earned in \(horizonTitle)")

        if let range = line.range(of: earned) {
            line[range].foregroundColor = DesignSystem.Color.textBrand
        }

        if let range = line.range(of: horizonTitle, options: .backwards) {
            line[range].foregroundColor = DesignSystem.Color.textPrimary
        }

        return line
    }
}

// MARK: - Constants

private extension EarnCalculatorHeaderView {
    enum Constants {
        static let spacing: CGFloat = 4
        static let menuLabelSpacing: CGFloat = 2
        static let totalBalanceMinimumScaleFactor: CGFloat = 0.5
    }
}
