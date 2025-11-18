//
//  YieldModuleEarnInfoChartContainer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct YieldModuleEarnInfoChartContainer: View {
    let state: YieldChartContainerState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            switch state {
            case .loading:
                YieldModuleChart(state: .loading)

            case .loaded(let data):
                YieldModuleChart(state: .loaded(apyData: data.buckets, xAxisLabels: data.xLabels, averageApy: data.averageApy))

            case .error(action: let retry):
                errorView { await retry() }
            }
        }
    }

    private func errorView(action: @escaping () async -> Void) -> some View {
        VStack {
            VStack(spacing: 12) {
                Text(Localization.yieldModuleChartLoadingError)
                    .style(Fonts.Regular.caption2, color: Colors.Text.tertiary)

                Button(action: { Task { await action() } }) {
                    Text(Localization.alertButtonTryAgain)
                        .style(Fonts.Regular.caption2, color: Colors.Text.primary1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.gray.opacity(0.2)))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 86)
        .defaultRoundedBackground(with: Colors.Background.action)
    }
}
