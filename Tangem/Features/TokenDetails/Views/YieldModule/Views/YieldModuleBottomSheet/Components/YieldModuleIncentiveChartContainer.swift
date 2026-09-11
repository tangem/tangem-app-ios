//
//  YieldModuleIncentiveChartContainer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct YieldModuleIncentiveChartContainer: View {
    let state: State
    let currentApyFormatted: String

    private let percentFormatter = PercentFormatter()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch state {
            case .loading:
                header(averageApy: nil, isLoading: true)
                YieldIncentiveChart(data: nil)

            case .loaded(let data):
                header(averageApy: data.averageApy, isLoading: false)
                YieldIncentiveChart(data: data)

            case .unavailable:
                header(averageApy: nil, isLoading: false)
                placeholderView(text: Localization.commonNotAvailable, retryAction: nil)

            case .error(action: let retry):
                // The current APY comes from the market state, not the failed history request — keep it visible.
                header(averageApy: nil, isLoading: false)
                placeholderView(text: Localization.yieldModuleChartLoadingError) { await retry() }
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private func header(averageApy: Double?, isLoading: Bool) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.yieldModuleEarnSheetCurrentApyTitle)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                HStack(spacing: 6) {
                    Triangle()
                        .fill(Colors.Icon.accent)
                        .frame(width: 12, height: 10)

                    Text(currentApyFormatted)
                        .style(Fonts.Bold.title2, color: Colors.Text.accent)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(Localization.yieldModuleIncentiveChartAverageApy)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Text(formattedAverage(averageApy))
                    .style(Fonts.Bold.title2, color: Colors.Text.secondary)
                    .skeletonable(isShown: isLoading)
            }
        }
    }

    private func formattedAverage(_ averageApy: Double?) -> String {
        guard let averageApy else { return AppConstants.emDashSign }

        return percentFormatter.format(Decimal(averageApy) / 100, option: .earn)
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
        .frame(maxWidth: .infinity)
        .frame(height: 158)
    }
}

// MARK: - State

extension YieldModuleIncentiveChartContainer {
    enum State: Equatable {
        case loading
        case loaded(YieldIncentiveChartData)
        case unavailable
        case error(action: () async -> Void)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading), (.unavailable, .unavailable), (.error, .error):
                return true
            case (.loaded(let lhsData), .loaded(let rhsData)):
                return lhsData == rhsData
            default:
                return false
            }
        }
    }
}
