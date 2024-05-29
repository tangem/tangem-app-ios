//
//  AverageRewardingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

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
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

            Text(data.rewardFormatted)
                .style(Fonts.Regular.callout, color: Colors.Text.accent)
        }
        .infinityFrame(axis: .horizontal, alignment: .leading)
    }

    private var trailingView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("30 day est. profit")
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

            Text(data.profitFormatted)
                .style(Fonts.Regular.callout, color: Colors.Text.primary1)
        }
        .lineLimit(1)
        .infinityFrame(axis: .horizontal, alignment: .leading)
    }
}

#Preview("AverageRewardingView") {
    ZStack {
        Colors.Background.secondary.ignoresSafeArea()

        GroupedSection(AverageRewardingViewData(
            rewardType: "APR",
            rewardFormatted: "4.23%",
            profitFormatted: "13.57$"
        )) {
            AverageRewardingView(data: $0)
        }
        .innerContentPadding(12)
        .padding()
    }
}
