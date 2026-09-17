//
//  PolymarketRedeemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI
import TangemUI
import TangemUIUtils

struct PolymarketRedeemView: View {
    @ObservedObject var viewModel: PolymarketRedeemViewModel

    var body: some View {
        StatusScreen(
            title: viewModel.title,
            description: viewModel.description,
            actionTitle: viewModel.actionTitle,
            action: { viewModel.handleViewAction(.primaryTapped) }
        )
        .appearance(viewModel.appearance)
        .actionIcon(viewModel.isActionClaim ? DesignSystem.Icons.LogoTangem.regular24 : nil)
        .actionLoading(viewModel.isClaiming)
        .footerCaption(viewModel.footerCaption)
        .details { details }
        .toolbar(.hidden, for: .navigationBar)
        .alert(item: $viewModel.alert) { $0.alert }
        .onDisappear { viewModel.handleViewAction(.disappeared) }
    }

    private var details: some View {
        VStack(spacing: Constants.blockSpacing) {
            PolymarketOrderMarketRow(model: viewModel.marketRow)

            if viewModel.investedText != nil || viewModel.profit != nil {
                rows
            }
        }
    }

    private var rows: some View {
        VStack(spacing: 0) {
            if let investedText = viewModel.investedText {
                TangemUI.Row(title: Localization.predictionPositionsInvested, value: investedText)
                    .showDivider(viewModel.profit != nil)
            }

            if let profit = viewModel.profit {
                profitRow(profit)
            }
        }
    }

    // [REDACTED_TODO_COMMENT]
    private func profitRow(_ profit: PolymarketRedeemViewModel.Profit) -> some View {
        TangemUI.Row(title: "Profit")
            .valueAccessory {
                UtilPriceChange(value: profit.text, direction: profit.direction)
            }
    }
}

// MARK: - Constants

private extension PolymarketRedeemView {
    enum Constants {
        static let blockSpacing: CGFloat = 8
    }
}
