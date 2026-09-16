//
//  MarketTokenRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemUI
import TangemUIUtils

struct MarketTokenRowView: View {
    @ObservedObject var viewModel: MarketTokenItemViewModel

    var body: some View {
        TokenRowMarket(
            .price(
                icon: .remote(name: viewModel.name, imageURL: viewModel.imageURL),
                title: viewModel.name,
                ticker: viewModel.symbol,
                rank: viewModel.marketRating,
                capitalisation: viewModel.marketCap,
                price: .loaded(viewModel.priceValue),
                priceChange: priceChange,
                graph: viewModel.charts,
                onTap: { viewModel.didTapAction?() }
            )
        )
        .accessibilityIdentifiers(
            TokenRowMarket.AccessibilityIdentifiers(
                name: MarketsAccessibilityIdentifiers.marketsListTokenNameLabel,
                ticker: MarketsAccessibilityIdentifiers.marketsListTokenCurrencyLabel,
                price: MarketsAccessibilityIdentifiers.marketsListTokenPrice,
                priceChange: MarketsAccessibilityIdentifiers.marketsListTokenPriceChange,
                capitalisation: MarketsAccessibilityIdentifiers.marketsListTokenMarketCap,
                rank: MarketsAccessibilityIdentifiers.marketsListTokenRating,
                icon: MarketsAccessibilityIdentifiers.marketsListTokenIcon,
                graph: MarketsAccessibilityIdentifiers.marketsListTokenChart
            )
        )
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsListTokenItem(uniqueId: viewModel.name))
    }

    private var priceChange: TokenRowPriceChange? {
        let direction: UtilPriceChange.Direction = switch viewModel.priceChangeState.changeType {
        case .positive: .positive
        case .negative: .negative
        case .neutral, nil: .neutral
        }

        switch viewModel.priceChangeState {
        case .loaded(_, let text):
            return TokenRowPriceChange(value: text, direction: direction)
        case .loadingCached(_, let text):
            return TokenRowPriceChange(value: text, direction: direction, isUpdating: true)
        default:
            return nil
        }
    }
}

// MARK: - Previews

#if DEBUG

private let previewTokens: [MarketsTokenModel] = [
    MarketsTokenModel(
        id: "bitcoin",
        name: "Bitcoin",
        symbol: "BTC",
        currentPrice: 67432.12,
        priceChangePercentage: ["24h": 2.35],
        marketRating: 1,
        maxYieldApy: nil,
        marketCap: 1_320_000_000_000,
        isUnderMarketCapLimit: false,
        stakingOpportunities: nil,
        networks: nil,
        restrictedForCountry: nil
    ),
    MarketsTokenModel(
        id: "ethereum",
        name: "Ethereum",
        symbol: "ETH",
        currentPrice: 3521.87,
        priceChangePercentage: ["24h": -1.12],
        marketRating: 2,
        maxYieldApy: 0.042,
        marketCap: 423_000_000_000,
        isUnderMarketCapLimit: false,
        stakingOpportunities: nil,
        networks: nil,
        restrictedForCountry: nil
    ),
    MarketsTokenModel(
        id: "solana",
        name: "Solana",
        symbol: "SOL",
        currentPrice: 142.55,
        priceChangePercentage: ["24h": 5.67],
        marketRating: 5,
        maxYieldApy: nil,
        marketCap: 62_000_000_000,
        isUnderMarketCapLimit: false,
        stakingOpportunities: nil,
        networks: nil,
        restrictedForCountry: nil
    ),
]

private func previewViewModel(for token: MarketsTokenModel) -> MarketTokenItemViewModel {
    MarketTokenItemViewModel(
        tokenModel: token,
        marketCapFormatter: MarketCapFormatter(
            divisorsList: AmountNotationSuffixFormatter.Divisor.defaultList,
            baseCurrencyCode: "USD",
            notationFormatter: DefaultAmountNotationFormatter()
        ),
        chartsProvider: MarketsListChartsHistoryProvider(),
        filterProvider: MarketsListDataFilterProvider(),
        onTapAction: nil
    )
}

#Preview {
    ScrollView(.vertical) {
        ForEach(previewTokens) { token in
            MarketTokenRowView(viewModel: previewViewModel(for: token))
        }
    }
}

#Preview("Dynamic Type - Accessibility1") {
    ScrollView(.vertical) {
        ForEach(previewTokens) { token in
            MarketTokenRowView(viewModel: previewViewModel(for: token))
        }
    }
    .environment(\.dynamicTypeSize, .accessibility1)
}

#endif // DEBUG
