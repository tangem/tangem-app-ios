//
//  TokenSummaryViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

@MainActor
final class TokenSummaryViewModel: ObservableObject, Identifiable {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    let tokenName: String
    let networkName: String
    let tokenIconInfo: TokenIconInfo

    @Published var selectedPeriod: TokenSummaryPeriod = .day
    @Published private(set) var outlook: TokenSummaryOutlook?
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var aiSummaryText: String?
    @Published private(set) var metrics: [TokenSummaryMetric]

    private let onGoToSwap: () -> Void
    private let onClose: () -> Void

    init(
        tokenName: String,
        networkName: String,
        tokenIconInfo: TokenIconInfo,
        outlook: TokenSummaryOutlook?,
        lastUpdated: Date?,
        aiSummaryText: String?,
        metrics: [TokenSummaryMetric],
        onGoToSwap: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.tokenName = tokenName
        self.networkName = networkName
        self.tokenIconInfo = tokenIconInfo
        self.outlook = outlook
        self.lastUpdated = lastUpdated
        self.aiSummaryText = aiSummaryText
        self.metrics = metrics
        self.onGoToSwap = onGoToSwap
        self.onClose = onClose
    }

    func goToSwapTapped() {
        onGoToSwap()
    }

    func closeTapped() {
        onClose()
    }

    func metricInfoTapped(_ metric: TokenSummaryMetric) {
        let infoViewModel = TokenSummaryMetricInfoViewModel(
            title: metric.title,
            info: metric.info,
            onClose: { [weak self] in
                self?.floatingSheetPresenter.removeActiveSheet()
            }
        )

        floatingSheetPresenter.enqueue(sheet: infoViewModel)
    }
}

// MARK: - Mock

extension TokenSummaryViewModel {
    // [REDACTED_TODO_COMMENT]
    static func mock(
        tokenItem: TokenItem,
        onGoToSwap: @escaping () -> Void = {},
        onClose: @escaping () -> Void = {}
    ) -> TokenSummaryViewModel {
        TokenSummaryViewModel(
            tokenName: tokenItem.name,
            networkName: tokenItem.networkName,
            tokenIconInfo: TokenIconInfoBuilder().build(from: tokenItem, isCustom: false),
            outlook: .positive,
            lastUpdated: Date(),
            aiSummaryText: "AI Total: the momentum looks strong across most indicators, though a short-term pullback is possible after such a fast run-up.",
            metrics: [
                TokenSummaryMetric(
                    title: "Galaxy Score",
                    value: "72",
                    sentiment: .positive,
                    info: "An indicator that evaluates the current state of a cryptocurrency based on its market indicators and the dynamics of social sentiment, developed by LunarCrush."
                ),
                TokenSummaryMetric(
                    title: "Sentiment",
                    value: "2.01",
                    sentiment: .positive,
                    info: "A measure of the overall mood of the market toward the asset, aggregated from social media and news activity."
                ),
                TokenSummaryMetric(
                    title: "RSI",
                    value: "61",
                    sentiment: .positive,
                    info: "The Relative Strength Index measures the speed and magnitude of recent price changes to signal overbought or oversold conditions."
                ),
                TokenSummaryMetric(
                    title: "MACD",
                    value: "145.67",
                    sentiment: .neutral,
                    info: "Moving Average Convergence Divergence tracks the relationship between two moving averages to reveal shifts in momentum."
                ),
                TokenSummaryMetric(
                    title: "MA Cross",
                    value: "50",
                    sentiment: .positive,
                    info: "Highlights when short- and long-term moving averages cross, a classic signal of a potential trend reversal."
                ),
            ],
            onGoToSwap: onGoToSwap,
            onClose: onClose
        )
    }
}
