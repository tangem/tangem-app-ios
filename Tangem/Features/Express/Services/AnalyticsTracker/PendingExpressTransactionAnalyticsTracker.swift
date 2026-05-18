//
//  PendingExpressTransactionAnalyticsTracker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol PendingExpressTransactionAnalyticsTracker {
    func trackStatusForSwapTransaction(
        transactionId: String,
        tokenSymbol: String,
        status: PendingExpressTransactionStatus,
        provider: ExpressPendingTransactionRecord.Provider
    ) async

    func trackStatusForOnrampTransaction(
        transactionId: String,
        tokenSymbol: String,
        currencySymbol: String,
        status: PendingExpressTransactionStatus,
        provider: ExpressPendingTransactionRecord.Provider
    ) async
}

private struct PendingExpressTransactionAnalyticsTrackerKey: InjectionKey {
    static var currentValue: PendingExpressTransactionAnalyticsTracker = CommonPendingExpressTransactionAnalyticsTracker()
}

extension InjectedValues {
    var pendingExpressTransactionAnalyticsTracker: PendingExpressTransactionAnalyticsTracker {
        get { Self[PendingExpressTransactionAnalyticsTrackerKey.self] }
        set { Self[PendingExpressTransactionAnalyticsTrackerKey.self] = newValue }
    }
}
