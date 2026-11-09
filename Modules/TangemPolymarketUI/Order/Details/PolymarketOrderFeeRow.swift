//
//  PolymarketOrderFeeRow.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

public struct PolymarketOrderFeeRow: View {
    private let title: String
    private let valueText: String
    private let currencyBadgeText: String?
    private let showsDivider: Bool
    private let onTap: (() -> Void)?

    public init(
        title: String = Localization.predictionPlaceFee,
        valueText: String,
        currencyBadgeText: String? = nil,
        showsDivider: Bool = true,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.valueText = valueText
        self.currencyBadgeText = currencyBadgeText
        self.showsDivider = showsDivider
        self.onTap = onTap
    }

    public var body: some View {
        TangemUI.Row(title: title)
            .titleAccessory { hintIcon }
            .valueAccessory { value }
            .showDivider(showsDivider)
            .onTap(action: onTap)
    }

    private var value: some View {
        HStack(spacing: Constants.valueSpacing) {
            if let currencyBadgeText {
                Badge(label: currencyBadgeText, accessibilityLabel: nil)
                    .size(.x6)
                    .variant(.tinted)
                    .appearance(.neutral)
            }

            Text(valueText)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var hintIcon: some View {
        if onTap != nil {
            PolymarketHintIcon(asset: DesignSystem.Icons.Info.regular16)
        }
    }
}

// MARK: - Constants

private extension PolymarketOrderFeeRow {
    enum Constants {
        static let valueSpacing: CGFloat = 8
    }
}
