//
//  AverageRewardingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct AverageRewardingView: View {
    let data: AverageRewardingViewData

    var body: some View {
        HStack(spacing: .zero) {
            leadingView

            trailingView
        }
        .infinityFrame(axis: .horizontal, alignment: .leading)
    }

    private var leadingView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(data.rewardType)
                .style(Fonts.Regular.footnote, color: DesignSystem.Color.textSecondary)

            Text(data.rewardFormatted)
                .style(Fonts.Regular.callout, color: DesignSystem.Color.textAccentBlue)
        }
        .infinityFrame(axis: .horizontal, alignment: .leading)
    }

    private var trailingView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Localization.stakingDetailsEstimatedProfit(data.periodProfitFormatted))
                .style(Fonts.Regular.footnote, color: DesignSystem.Color.textSecondary)

            LoadableTextView(
                state: data.profitFormatted,
                font: Fonts.Regular.callout,
                textColor: DesignSystem.Color.textPrimary,
                loaderSize: CGSize(width: 40, height: 14)
            )
        }
        .lineLimit(1)
        .infinityFrame(axis: .horizontal, alignment: .leading)
    }
}

#Preview("AverageRewardingView") {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        GroupedSection([
            AverageRewardingViewData(
                rewardType: "APR",
                rewardFormatted: "4.23%",
                periodProfitFormatted: "30 days",
                profitFormatted: .loaded(text: "13.57$")
            ),
            AverageRewardingViewData(
                rewardType: "APR",
                rewardFormatted: "4.23%",
                periodProfitFormatted: "30 days",
                profitFormatted: .noData
            ),
        ]) {
            AverageRewardingView(data: $0)
        }
        .innerContentPadding(12)
        .padding()
    }
}
