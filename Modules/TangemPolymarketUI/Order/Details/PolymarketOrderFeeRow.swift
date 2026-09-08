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
    private let currencyCode: String
    private let valueText: String

    public init(currencyCode: String, valueText: String) {
        self.currencyCode = currencyCode
        self.valueText = valueText
    }

    public var body: some View {
        TangemUI.Row(title: Localization.predictionPlaceFee)
            .valueAccessory { value }
            .showDivider()
    }

    private var value: some View {
        HStack(spacing: Constants.spacing) {
            Badge(label: currencyCode, accessibilityLabel: nil)
                .size(.x6)

            Text(valueText)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)

            PolymarketHintIcon(asset: DesignSystem.Icons.ChevronDoubleVertical.regular16)
        }
    }
}

// MARK: - Constants

private extension PolymarketOrderFeeRow {
    enum Constants {
        static let spacing: CGFloat = 8
    }
}
