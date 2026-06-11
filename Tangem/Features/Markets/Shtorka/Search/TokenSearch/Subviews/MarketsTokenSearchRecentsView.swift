//
//  MarketsTokenSearchRecentsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct MarketsTokenSearchRecentsView: View {
    let queries: [String]
    let marketAssetViewModels: [MarketTokenItemViewModel]
    let onQueryTap: (String) -> Void
    let onClearAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView

            querySection
                .padding(.top, .unit(.x3))

            marketAssetSection
                .padding(.top, .unit(.x6))
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(alignment: .center, spacing: .zero) {
            Text(Localization.marketsSearchHintHeader)
                .lineLimit(1)
                .style(.Tangem.Heading20.semibold, color: .Tangem.Text.Neutral.primary)

            Spacer(minLength: .unit(.x2))

            Button(action: onClearAll) {
                Text(Localization.marketsSearchClearAllHints)
                    .style(.Tangem.Body16.medium, color: .Tangem.Text.Neutral.primary)
            }
        }
        .padding(.vertical, .unit(.x3))
        .padding(.horizontal, .unit(.x2))
    }

    // MARK: - Query Rows

    @ViewBuilder
    private var querySection: some View {
        if queries.isNotEmpty {
            VStack(spacing: 0) {
                ForEach(Array(queries.enumerated()), id: \.offset) { index, query in
                    MarketsTokenSearchQueryRowView(query: query, onTap: { onQueryTap(query) })

                    if index < queries.count - 1 {
                        Separator(color: .Tangem.Border.Neutral.primary)
                    }
                }
            }
            .padding(.horizontal, .unit(.x2))
        }
    }

    // MARK: - Market Asset Rows

    @ViewBuilder
    private var marketAssetSection: some View {
        if marketAssetViewModels.isNotEmpty {
            VStack(alignment: .leading, spacing: .unit(.x3)) {
                Text(Localization.marketsCommonTitle)
                    .lineLimit(1)
                    .style(.Tangem.Heading20.semibold, color: .Tangem.Text.Neutral.primary)
                    .padding(.horizontal, .unit(.x2))
                    .padding(.bottom, .unit(.x2))
                    .padding(.top, .unit(.x4))

                VStack(spacing: .unit(.x2)) {
                    ForEach(marketAssetViewModels, id: \.tokenId) { viewModel in
                        MarketTokenRowView(viewModel: viewModel)
                            .roundedBackground(
                                with: .Tangem.Surface.level3,
                                padding: 0,
                                radius: .unit(.x5)
                            )
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    MarketsTokenSearchRecentsView(
        queries: ["Usdt", "Eth", "volume > 1M"],
        marketAssetViewModels: [],
        onQueryTap: { _ in },
        onClearAll: {}
    )
    .padding(.horizontal, .unit(.x4))
    .background(Color.Tangem.Surface.level2)
}
#endif // DEBUG
