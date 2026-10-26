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
    func logClosed(data: YieldModePromoSheetData, method: YieldModePromoCloseMethod)
    func logTryYieldMode(data: YieldModePromoSheetData)
}

struct CommonYieldModePromoAnalyticsLogger: YieldModePromoAnalyticsLogger {
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

    static func formatAPY(_ apy: Decimal) -> String {
        PercentFormatter(locale: .posixEnUS).format(apy, option: .interval)
    }
}

// MARK: - YieldModePromoCloseMethod

enum YieldModePromoCloseMethod: String {
    case cross = "X"
    case swipe = "Swipe"
}
