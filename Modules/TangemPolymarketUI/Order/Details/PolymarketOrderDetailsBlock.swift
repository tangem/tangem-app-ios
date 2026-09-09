//
//  PolymarketOrderDetailsBlock.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct PolymarketOrderDetailsBlock: View {
    private let currencyCode: String
    private let feeText: String
    private let slippageText: String
    private let onFeeTap: (() -> Void)?
    private let onSlippageTap: (() -> Void)?

    public init(
        currencyCode: String,
        feeText: String,
        slippageText: String,
        onFeeTap: (() -> Void)? = nil,
        onSlippageTap: (() -> Void)? = nil
    ) {
        self.currencyCode = currencyCode
        self.feeText = feeText
        self.slippageText = slippageText
        self.onFeeTap = onFeeTap
        self.onSlippageTap = onSlippageTap
    }

    public var body: some View {
        VStack(spacing: 0) {
            PolymarketOrderFeeRow(currencyCode: currencyCode, valueText: feeText, onTap: onFeeTap)

            PolymarketOrderSlippageRow(valueText: slippageText, onTap: onSlippageTap)
        }
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
    }
}

// MARK: - Constants

private extension PolymarketOrderDetailsBlock {
    enum Constants {
        static let cornerRadius: CGFloat = 24
    }
}
