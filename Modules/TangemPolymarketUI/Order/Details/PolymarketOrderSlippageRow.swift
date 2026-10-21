//
//  PolymarketOrderSlippageRow.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

public struct PolymarketOrderSlippageRow: View {
    private let valueText: String
    private let showsDivider: Bool
    private let onTap: (() -> Void)?

    public init(valueText: String, showsDivider: Bool = false, onTap: (() -> Void)? = nil) {
        self.valueText = valueText
        self.showsDivider = showsDivider
        self.onTap = onTap
    }

    public var body: some View {
        TangemUI.Row(title: Localization.predictionPlaceSlippage, value: valueText)
            .valueAccessory { chevron }
            .showDivider(showsDivider)
            .onTap(action: onTap)
    }

    @ViewBuilder
    private var chevron: some View {
        if onTap != nil {
            PolymarketHintIcon(
                asset: DesignSystem.Icons.ChevronDoubleVertical.regular20,
                side: PolymarketHintIcon.Constants.selectSide
            )
        }
    }
}
