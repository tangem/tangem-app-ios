//
//  NoOpAddTokenFlowAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

final class NoOpAddTokenFlowAnalyticsLogger: AddTokenFlowAnalyticsLogger {
    func logTokenAdded(tokenItem: TokenItem, isMainAccount: Bool) {}
    func logAddTokenButtonTapped() {}
    func logAddTokenScreenOpened() {}
    func logBuyTapped() {}
    func logExchangeTapped() {}
    func logReceiveTapped() {}
    func logLaterTapped() {}
    func logAccountSelectorOpened() {}
}
