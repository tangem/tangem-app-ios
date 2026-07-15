//
//  PortfolioTokenListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

/// Portfolio Review token list: a stack of collapsible asset group cards.
struct PortfolioTokenListView: View {
    @ObservedObject var viewModel: PortfolioTokenListViewModel

    var body: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.items) { item in
                PortfolioTokenItemView(
                    item: item,
                    onAssetTap: viewModel.toggleAsset
                )
            }
        }
    }
}

// MARK: - Previews

#Preview("Content") {
    func item(id: String, symbol: String, subtitle: String, fiat: String, percent: String) -> ForYouTokenListItem {
        ForYouTokenListItem(
            id: id,
            assetRow: ForYouTokenRowData(
                id: id,
                isLoading: false,
                symbol: symbol,
                tokenIconInfo: nil,
                sentiment: .positive,
                subtitle: .text(subtitle),
                end: .values(fiat: fiat, percent: percent)
            ),
            networkRows: [],
            isExpanded: false,
            isExpandable: true
        )
    }

    return PortfolioTokenListView(
        viewModel: PortfolioTokenListViewModel(
            items: [
                item(id: "btc", symbol: "Bitcoin", subtitle: "Main network", fiat: "$849", percent: "8.49%"),
                item(id: "sol", symbol: "Solana", subtitle: "2 networks", fiat: "$700", percent: "7.0%"),
            ]
        )
    )
    .padding(16)
}

#Preview("Loading") {
    PortfolioTokenListView(
        viewModel: PortfolioTokenListViewModel(
            items: PortfolioReviewState.loadingPlaceholder.tokenList
        )
    )
    .padding(16)
}
