//
//  CommonTokenSummaryAnalyticsLogger.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CommonTokenSummaryAnalyticsLogger: TokenSummaryAnalyticsLogger {
    private let token: String
    private let blockchain: String?

    init(tokenItem: TokenItem) {
        token = tokenItem.currencySymbol
        blockchain = tokenItem.blockchain.displayName
    }

    /// A Markets coin spans several networks, so it reports no blockchain.
    init(symbol: String) {
        token = symbol
        blockchain = nil
    }

    func logOpened() {
        Analytics.log(event: .forYouTokenSummary, params: defaultParams())
    }

    func logInterval(period: TokenSummaryPeriod) {
        Analytics.log(
            event: .forYouTokenSummaryInterval,
            params: defaultParams(adding: [.period: ForYouAnalytics.Period(period).rawValue])
        )
    }

    func logPrimaryAction(kind: TokenSummaryPrimaryAction.Kind) {
        let event: Analytics.Event = switch kind {
        case .goToSwap: .forYouGoToSwap
        case .addFunds: .forYouAddFunds
        }

        Analytics.log(event: event, params: defaultParams())
    }

    func logIndicatorInfo(kind: TokenSummaryIndicator.Kind) {
        guard let indicator = ForYouAnalytics.Indicator(kind) else {
            return
        }

        Analytics.log(
            event: .forYouIndicatorInfo,
            params: [.info: indicator.rawValue, .source: ForYouAnalytics.Source.forYou.rawValue]
        )
    }

    private func defaultParams(
        adding additionalParams: [Analytics.ParameterKey: String] = [:]
    ) -> [Analytics.ParameterKey: String] {
        var params: [Analytics.ParameterKey: String] = [
            .token: token,
            .source: ForYouAnalytics.Source.forYou.rawValue,
        ]

        if let blockchain {
            params[.blockchain] = blockchain
        }

        params.merge(additionalParams) { _, new in new }
        return params
    }
}
