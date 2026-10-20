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
    private let valueText: String
    private let showsDivider: Bool
    private let onTap: (() -> Void)?

    public init(valueText: String, showsDivider: Bool = true, onTap: (() -> Void)? = nil) {
        self.valueText = valueText
        self.showsDivider = showsDivider
        self.onTap = onTap
    }

    public var body: some View {
        TangemUI.Row(title: Localization.predictionPlaceFee)
            .titleAccessory { hintIcon }
            .valueAccessory { value }
            .showDivider(showsDivider)
            .onTap(action: onTap)
    }

    private var value: some View {
        Text(valueText)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
            .lineLimit(1)
    }

    @ViewBuilder
    private var hintIcon: some View {
        if onTap != nil {
            PolymarketHintIcon(asset: DesignSystem.Icons.Info.regular16)
        }
    }
}
