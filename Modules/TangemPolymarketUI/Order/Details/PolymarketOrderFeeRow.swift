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
    private let showsDivider: Bool
    private let onTap: (() -> Void)?

    public init(currencyCode: String, valueText: String, showsDivider: Bool = true, onTap: (() -> Void)? = nil) {
        self.currencyCode = currencyCode
        self.valueText = valueText
        self.showsDivider = showsDivider
        self.onTap = onTap
    }

    public var body: some View {
        let row = TangemUI.Row(title: Localization.predictionPlaceFee)
            .valueAccessory { value }
            .showDivider(showsDivider)

        if let onTap {
            row.onTap(onTap)
        } else {
            row
        }
    }

    private var value: some View {
        HStack(spacing: Constants.spacing) {
            Badge(label: currencyCode, accessibilityLabel: nil)
                .size(.x6)

            Text(valueText)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)

            if onTap != nil {
                PolymarketHintIcon(asset: DesignSystem.Icons.Info.regular16)
            }
        }
    }
}

// MARK: - Constants

private extension PolymarketOrderFeeRow {
    enum Constants {
        static let spacing: CGFloat = 8
    }
}
