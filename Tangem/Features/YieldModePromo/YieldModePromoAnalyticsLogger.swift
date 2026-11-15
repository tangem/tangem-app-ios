//
//  YieldModePromoAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol YieldModePromoAnalyticsLogger {
    func logOpened(data: YieldModePromoSheetData)
    func logSkipped(reason: MainScreenPromoSheetSkipReason)
    func logClosed(data: YieldModePromoSheetData, method: YieldModePromoCloseMethod)
    func logTryYieldMode(data: YieldModePromoSheetData)
}

struct CommonYieldModePromoAnalyticsLogger: YieldModePromoAnalyticsLogger {
    func logOpened(data: YieldModePromoSheetData) {
        Analytics.log(
            event: .earningPromoScreenOpened,
            params: offerParams(data).merging([.tokensCount: String(data.tokensCount)]) { $1 }
        )
    }

    func logSkipped(reason: MainScreenPromoSheetSkipReason) {
        Analytics.log(event: .earningPromoScreenSkipped, params: [.reason: Self.skipReasonValue(reason)])
    }

    func logClosed(data: YieldModePromoSheetData, method: YieldModePromoCloseMethod) {
        Analytics.log(
            event: .earningPromoScreenClosed,
            params: offerParams(data).merging([.closeMethod: method.rawValue]) { $1 }
        )
    }

    func logTryYieldMode(data: YieldModePromoSheetData) {
        Analytics.log(event: .earningButtonTryYieldMode, params: offerParams(data))
    }

    private func offerParams(_ data: YieldModePromoSheetData) -> [Analytics.ParameterKey: String] {
        [
            .token: data.tokenSymbol,
            .blockchain: data.blockchainName,
            .apy: Self.formatAPY(data.apy),
        ]
    }

    static func skipReasonValue(_ reason: MainScreenPromoSheetSkipReason) -> String {
        switch reason {
        case .surfaceBusy: "Surface Busy"
        case .dataNotReady: "Data Not Ready"
        case .noEligibleContent: "No Eligible Token"
        case .variantNotReady: "Variant Not Ready"
        }
    }

    static func formatAPY(_ apy: Decimal) -> String {
        PercentFormatter(locale: .posixEnUS).format(apy, option: .interval)
    }
}

// MARK: - YieldModePromoCloseMethod

enum YieldModePromoCloseMethod: String {
    case cross = "X"
    case swipe = "Swipe"
}
