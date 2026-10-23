//
//  PolymarketOrderAmountPreviews.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

private struct PolymarketOrderAmountShowcase: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PolymarketOrderAmountBlock(payment: .empty, isAddFundsEnabled: true, onAddFunds: {}) {
                    amount("$ 0")
                }

                PolymarketOrderAmountBlock(payment: .funded, isAddFundsEnabled: true, onAddFunds: {}) {
                    amount("$ 4,000")
                }

                PolymarketOrderAmountBlock(payment: .empty, isAddFundsEnabled: false, onAddFunds: {}) {
                    amount("$ 0")
                }
            }
            .padding(16)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }

    private func amount(_ text: String) -> some View {
        Text(text)
            .style(DesignSystem.Font.displayMediumToken, color: DesignSystem.Color.textPrimary)
    }
}

private extension PolymarketOrderPaymentRow.Model {
    static let empty = Self(icon: Assets.Polymarket.accountAvatar, symbol: "USD", balanceText: "$0,00")
    static let funded = Self(icon: Assets.Polymarket.accountAvatar, symbol: "USD", balanceText: "$30,000")
}

// MARK: - Previews

#Preview("Showcase") {
    PolymarketOrderAmountShowcase()
}

#Preview("Showcase — Dark") {
    PolymarketOrderAmountShowcase()
        .preferredColorScheme(.dark)
}
