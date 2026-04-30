//
//  MarketsTokenDetailsMetricsViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MarketsTokenDetailsMetricsViewRedesign: View {
    let viewModel: MarketsTokenDetailsMetricsViewModel

    var body: some View {
        VStack(spacing: .unit(.x2)) {
            HStack(spacing: .unit(.x2)) {
                MetricsMarketCapCard(viewModel: viewModel)

                MetricsTradingVolumeCard(viewModel: viewModel)
            }

            HStack(spacing: .unit(.x2)) {
                MetricsMarketPositionCard(viewModel: viewModel)

                MetricsFDVCard(viewModel: viewModel)
            }

            MetricsCirculatingSupplyCard(viewModel: viewModel)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    ScrollView {
        MarketsTokenDetailsMetricsViewRedesign(
            viewModel: MarketsTokenDetailsMetricsViewModel(
                metrics: MarketsTokenDetailsMetrics(
                    marketRating: 1,
                    marketRatingChange24H: nil,
                    circulatingSupply: 19_930_000,
                    marketCap: 2_440_000_000_000,
                    volume24H: 7_900_000_000_000,
                    totalSupply: 21_000_000,
                    maxSupply: 21_000_000,
                    fullyDilutedValuation: 2_785_400_000_000
                ),
                notationFormatter: DefaultAmountNotationFormatter(),
                cryptoCurrencyCode: "KAS",
                infoRouter: nil
            )
        )
        .padding(.horizontal, 16)
    }
    .background(Color.Tangem.Surface.level2)
}

#Preview("Silver rank, medium liquidity") {
    ScrollView {
        MarketsTokenDetailsMetricsViewRedesign(
            viewModel: MarketsTokenDetailsMetricsViewModel(
                metrics: MarketsTokenDetailsMetrics(
                    marketRating: 2,
                    marketRatingChange24H: 1,
                    circulatingSupply: 112_259_808_785,
                    marketCap: 112_234_033_891,
                    volume24H: 42_854_017_104,
                    totalSupply: 112_286_364_258,
                    maxSupply: 112_286_364_258,
                    fullyDilutedValuation: 112_234_033_891
                ),
                notationFormatter: DefaultAmountNotationFormatter(),
                cryptoCurrencyCode: "USDT",
                infoRouter: nil
            )
        )
        .padding(.horizontal, 16)
    }
    .background(Color.Tangem.Surface.level2)
}

#Preview("No max supply") {
    ScrollView {
        MarketsTokenDetailsMetricsViewRedesign(
            viewModel: MarketsTokenDetailsMetricsViewModel(
                metrics: MarketsTokenDetailsMetrics(
                    marketRating: 42,
                    marketRatingChange24H: -15,
                    circulatingSupply: 18_900_000,
                    marketCap: 500_000_000_000,
                    volume24H: 50_000_000_000,
                    totalSupply: nil,
                    maxSupply: 0,
                    fullyDilutedValuation: 600_000_000_000
                ),
                notationFormatter: DefaultAmountNotationFormatter(),
                cryptoCurrencyCode: "ETH",
                infoRouter: nil
            )
        )
        .padding(.horizontal, 16)
    }
    .background(Color.Tangem.Surface.level2)
}
#endif
