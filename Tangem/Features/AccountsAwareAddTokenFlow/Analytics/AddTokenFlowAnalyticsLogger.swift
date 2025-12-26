//
//  AddTokenFlowAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

/// Composite analytics logger for the AccountsAwareAddTokenFlow
protocol AddTokenFlowAnalyticsLogger: AddTokenAnalyticsLogger, GetTokenAnalyticsLogger, AccountSelectorAnalyticsLogger {}

// MARK: - AddTokenAnalyticsLogger

protocol AddTokenAnalyticsLogger {
    func logTokenAdded(tokenItem: TokenItem, isMainAccount: Bool)
}

// MARK: - GetTokenAnalyticsLogger

protocol GetTokenAnalyticsLogger {
    func logBuyTapped()
    func logExchangeTapped()
    func logReceiveTapped()
    func logLaterTapped()
}

// MARK: - AccountSelectorAnalyticsLogger

protocol AccountSelectorAnalyticsLogger {
    func logAccountSelectorOpened()
}
