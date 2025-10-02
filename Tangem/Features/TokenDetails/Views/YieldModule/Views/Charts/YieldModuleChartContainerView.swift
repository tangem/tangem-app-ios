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

struct YieldModuleChartContainer: View {
    @StateObject
    private var viewModel = YieldModuleChartViewModel()

    var body: some View {
        content
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loaded, .loading:
            chart

        case .error(let action):
            errorView(action: action)
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
        .frame(height: 156)
        .defaultRoundedBackground()
    }

    private var chart: some View {
        VStack(alignment: .leading, spacing: 6) {
            title
            description
            YieldModuleChart(state: viewModel.state)
        }
        .defaultRoundedBackground()
        .task {
            await viewModel.loadData()
        }
    }

    private var title: some View {
        Text(Localization.yieldModuleRateInfoSheetChartTitle)
            .style(Fonts.Bold.headline, color: Colors.Text.primary1)
            .skeletonable(isShown: viewModel.state.isLoading)
    }

    private var description: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Colors.Icon.accent)
                .frame(width: 8, height: 8)

            Text(Localization.yieldModuleSupplyApr)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
        }
        .skeletonable(isShown: viewModel.state.isLoading)
    }
}
