//
//  AccountTotalBalanceProviderAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

/// `TotalBalanceProviderAnalyticsLogger` should be use for each special account. Not for general combined total balance
class AccountTotalBalanceProviderAnalyticsLogger {}

// MARK: - TotalBalanceProviderAnalyticsLogger

extension AccountTotalBalanceProviderAnalyticsLogger: TotalBalanceProviderAnalyticsLogger {
    func setupTotalBalanceState(publisher: AnyPublisher<TotalBalanceState, Never>) {}
}
