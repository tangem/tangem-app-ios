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
    private let onTap: (() -> Void)?

    public init(valueText: String, onTap: (() -> Void)? = nil) {
        self.valueText = valueText
        self.onTap = onTap
    }

    public var body: some View {
        let row = TangemUI.Row(title: Localization.predictionPlaceSlippage, value: valueText)
            .valueAccessory { chevron }

        if let onTap {
            row.onTap(onTap)
        } else {
            row
        }
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
