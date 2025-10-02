//
//  YieldModuleChartContainerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct YieldMduleChartContainer: View {
    let data: YieldChartData

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            title
            description
            YieldModuleChart(data: data)
        }
        .padding(.bottom, 8)
        .defaultRoundedBackground()
    }

    private var title: some View {
        Text(Localization.yieldModuleRateInfoSheetChartTitle)
            .style(Fonts.Bold.headline, color: Colors.Text.primary1)
    }

    private var description: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Colors.Icon.accent)
                .frame(width: 8, height: 8)

            Text("Supply APR")
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
        }
    }
}
