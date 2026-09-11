//
//  PolymarketOrderDetailsPreviews.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

private struct PolymarketOrderDetailsShowcase: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.sectionSpacing) {
                section("Summary, both rows read only") {
                    PolymarketOrderDetailsBlock(currencyCode: "USDT", feeText: "$1.40", slippageText: "Default 0,25%")
                }

                section("Amount form, slippage opens the picker") {
                    PolymarketOrderDetailsBlock(
                        currencyCode: "USDT",
                        feeText: "$1.40",
                        slippageText: "0,5%",
                        onSlippageTap: {}
                    )
                }

                section("No quote yet") {
                    PolymarketOrderDetailsBlock(currencyCode: "USDC", feeText: "", slippageText: "Max 3%")
                }
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.vertical, Constants.sectionSpacing)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Constants.titleSpacing) {
            Text(title)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textTertiary)

            content()
        }
    }
}

// MARK: - Constants

private extension PolymarketOrderDetailsShowcase {
    enum Constants {
        static let sectionSpacing: CGFloat = 32
        static let titleSpacing: CGFloat = 8
        static let horizontalPadding: CGFloat = 16
    }
}

// MARK: - Previews

#Preview("Showcase") {
    PolymarketOrderDetailsShowcase()
}

#Preview("Showcase — Dark") {
    PolymarketOrderDetailsShowcase()
        .preferredColorScheme(.dark)
}
