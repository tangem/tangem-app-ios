//
//  TotalBalanceProviderAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

protocol TotalBalanceProviderAnalyticsLogger {
    func setupTotalBalanceState(publisher: AnyPublisher<TotalBalanceState, Never>)
}
