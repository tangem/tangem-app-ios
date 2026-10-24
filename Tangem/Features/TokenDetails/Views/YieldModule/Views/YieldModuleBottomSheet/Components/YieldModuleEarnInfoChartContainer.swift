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
    let kind: Kind
    let state: State

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            switch state {
            case .loading:
                skeletonView

            case .legacy(let data):
                YieldModuleChart(state: .loaded(apyData: data.buckets, xAxisLabels: data.xLabels, averageApy: data.averageApy))

            case .incentive(let data):
                YieldIncentiveChart(data: data)

            case .unavailable:
                placeholderView(text: Localization.commonNotAvailable, retryAction: nil)

            case .error(action: let retry):
                placeholderView(text: Localization.yieldModuleChartLoadingError) { await retry() }
            }
        }
        .frame(height: kind.chartHeight)
    }

    @ViewBuilder
    private var skeletonView: some View {
        switch kind {
        case .legacy:
            YieldModuleChart(state: .loading)

        case .incentive:
            YieldIncentiveChart(data: nil)
        }
    }

    private func placeholderView(text: String, retryAction: (() async -> Void)?) -> some View {
        VStack {
            VStack(spacing: 12) {
                Text(text)
                    .style(Fonts.Regular.caption2, color: Colors.Text.tertiary)

                if let retryAction {
                    SwiftUI.Button(action: { Task { await retryAction() } }) {
                        Text(Localization.alertButtonTryAgain)
                            .style(Fonts.Regular.caption2, color: Colors.Text.primary1)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.gray.opacity(0.2)))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .defaultRoundedBackground(with: Colors.Background.action)
    }
}

// MARK: - Kind

extension YieldModuleEarnInfoChartContainer {
    /// Which chart the sheet draws. Kept apart from `State` so the skeleton and the placeholders take up
    /// as much room as the chart that replaces them, instead of resizing the sheet once the data lands.
    enum Kind {
        case legacy
        case incentive

        var chartHeight: CGFloat {
            switch self {
            case .legacy: Constants.legacyChartHeight
            case .incentive: Constants.incentiveChartHeight
            }
        }
    }
}

// MARK: - State

extension YieldModuleEarnInfoChartContainer {
    enum State: Equatable {
        case loading
        case legacy(YieldChartData)
        case incentive(YieldIncentiveChartData)
        case unavailable
        case error(action: () async -> Void)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading), (.unavailable, .unavailable), (.error, .error):
                return true
            case (.legacy(let lhsData), .legacy(let rhsData)):
                return lhsData == rhsData
            case (.incentive(let lhsData), .incentive(let rhsData)):
                return lhsData == rhsData
            default:
                return false
            }
        }
    }
}

// MARK: - Constants

private extension YieldModuleEarnInfoChartContainer {
    enum Constants {
        static let legacyChartHeight: CGFloat = 110
        /// The 128pt plot plus the axis label row Charts lays out under it.
        static let incentiveChartHeight: CGFloat = 146
    }
}
