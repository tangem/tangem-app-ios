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
                .padding(.top, 12)

            marketAssetSection
                .padding(.top, 24)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(alignment: .center, spacing: .zero) {
            Text(Localization.marketsSearchHintHeader)
                .lineLimit(1)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

            Spacer(minLength: 8)

            SwiftUI.Button(action: onClearAll) {
                Text(Localization.marketsSearchClearAllHints)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
    }

    // MARK: - Query Rows

    @ViewBuilder
    private var querySection: some View {
        if queries.isNotEmpty {
            VStack(spacing: 0) {
                ForEach(Array(queries.enumerated()), id: \.offset) { index, query in
                    MarketsTokenSearchQueryRowView(query: query, onTap: { onQueryTap(query) })

                    if index < queries.count - 1 {
                        Separator(color: DesignSystem.Color.borderSecondary)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Market Asset Rows

    @ViewBuilder
    private var marketAssetSection: some View {
        if marketAssetViewModels.isNotEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(Localization.marketsCommonTitle)
                    .lineLimit(1)
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                    .padding(.top, 16)

                VStack(spacing: 8) {
                    ForEach(marketAssetViewModels, id: \.tokenId) { viewModel in
                        MarketTokenRowView(viewModel: viewModel)
                            .roundedBackground(
                                with: DesignSystem.Color.bgSecondary,
                                padding: 0,
                                radius: 20
                            )
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    MarketsTokenSearchRecentsView(
        queries: ["Usdt", "Eth", "volume > 1M"],
        marketAssetViewModels: [],
        onQueryTap: { _ in },
        onClearAll: {}
    )
    .padding(.horizontal, 16)
    .background(DesignSystem.Color.bgPrimary)
}
