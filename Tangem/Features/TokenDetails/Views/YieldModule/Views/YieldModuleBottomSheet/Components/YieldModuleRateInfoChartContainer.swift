//
//  YieldModuleRateInfoChartContainerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct YieldModuleRateInfoChartContainer: View {
    let state: YieldChartContainerState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch state {
            case .loading:
                makeTopContent(isLoading: true)
                YieldModuleChart(state: .loading)

            case .loaded(let data):
                makeTopContent(isLoading: false)
                YieldModuleChart(state: .loaded(apyData: data.buckets, xAxisLabels: data.xLabels, averageApy: data.averageApy))

            case .error(action: let retry):
                errorView { await retry() }
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private func makeTopContent(isLoading: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            title(isLoading: isLoading)
                .skeletonable(isShown: isLoading)

            description(isLoading: isLoading)
                .skeletonable(isShown: isLoading)
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
        .frame(height: 158)
    }

    private func title(isLoading: Bool) -> some View {
        Text(Localization.yieldModuleRateInfoSheetChartTitle)
            .style(Fonts.Bold.headline, color: Colors.Text.primary1)
            .skeletonable(isShown: isLoading)
    }

    private func description(isLoading: Bool) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Colors.Icon.accent)
                .frame(width: 8, height: 8)

            Text(Localization.yieldModuleSupplyApr)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
        }
        .skeletonable(isShown: isLoading)
    }
}
