//
//  PortfolioReviewChartCardView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct PortfolioReviewChartCardView: View {
    let chart: PortfolioReviewViewModel.ViewState.Chart

    @State private var selectedID: GaugeSegment.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            gauge
            summary
        }
        .padding(.bottom, 16)
        .portfolioTokenCard()
        .contentShape(Rectangle())
        .onTapGesture {
            guard selectedID != nil else { return }
            withAnimation { selectedID = nil }
        }
    }
}

private extension PortfolioReviewChartCardView {
    var gauge: some View {
        SummaryGaugeView(assets: gaugeAssets, noDataText: gaugeNoDataText, selectedID: $selectedID)
    }

    var gaugeAssets: [SummaryGaugeAsset] {
        guard case .loaded(let assets, _, _) = chart else { return [] }
        return assets
    }

    var gaugeNoDataText: String? {
        switch chart {
        case .loaded:
            return nil
        case .noData(.cantLoad):
            return Localization.marketChartBubbleNoData
        case .noData(.noAmount):
            return Localization.marketChartBubbleNoAmount
        }
    }

    @ViewBuilder
    var summary: some View {
        switch chart {
        case .loaded(_, let assetCount, let topHoldingPercent):
            VStack(alignment: .leading, spacing: 0) {
                Text(Localization.commonAssetsCount(assetCount))
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textSecondary)

                Text(Localization.marketChartTopHolding(topHoldingPercent))
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
        case .noData(let reason):
            Text(cardTitle(for: reason))
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
        }
    }

    func cardTitle(for reason: PortfolioReviewViewModel.ViewState.Chart.NoData) -> String {
        switch reason {
        case .cantLoad: return Localization.marketChartCanNotLoadData
        case .noAmount: return Localization.marketChartNoAmount
        }
    }
}
