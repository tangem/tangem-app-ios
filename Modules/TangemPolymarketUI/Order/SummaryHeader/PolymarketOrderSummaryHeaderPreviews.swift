//
//  PolymarketOrderSummaryHeaderPreviews.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

private struct PolymarketOrderSummaryHeaderShowcase: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.spacing) {
                PolymarketOrderSummaryHeader(model: .loadedStub)
                PolymarketOrderSummaryHeader(model: .refreshingStub)
                PolymarketOrderSummaryHeader(model: .loadingStub)
                PolymarketOrderSummaryHeader(model: .unavailableStub)
                PolymarketOrderSummaryHeader(model: .noQuoteStub)
                PolymarketOrderSummaryHeader(model: .longAmountStub)
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.vertical, Constants.spacing)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }
}

// MARK: - Constants

private extension PolymarketOrderSummaryHeaderShowcase {
    enum Constants {
        static let spacing: CGFloat = 24
        static let horizontalPadding: CGFloat = 16
    }
}

// MARK: - Stubs

private extension PolymarketOrderSummaryHeader.Model {
    static func stub(
        amountText: String = "$4,000",
        toWin: PolymarketAmountBadge.State? = .value("$4,705.88")
    ) -> Self {
        Self(
            accountName: "Polymarket account",
            accountIcon: Assets.Polymarket.accountAvatar,
            sourceTitle: "From",
            balanceText: "Balance: $30,000",
            amountText: amountText,
            toWin: toWin
        )
    }

    static let loadedStub = stub()
    static let refreshingStub = stub(toWin: .loading(previousValue: "$4,705.88"))
    static let loadingStub = stub(toWin: .loading(previousValue: nil))
    static let unavailableStub = stub(toWin: .unavailable)
    static let noQuoteStub = stub(toWin: nil)
    static let longAmountStub = stub(amountText: "$1,284,900.75", toWin: .value("$1,510,471.47"))
}

// MARK: - Previews

#Preview("Showcase") {
    PolymarketOrderSummaryHeaderShowcase()
}

#Preview("Showcase — Dark") {
    PolymarketOrderSummaryHeaderShowcase()
        .preferredColorScheme(.dark)
}
