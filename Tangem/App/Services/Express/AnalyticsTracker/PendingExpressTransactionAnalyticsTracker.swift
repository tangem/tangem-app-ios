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
    func trackStatusForTransaction(
        branch: ExpressBranch,
        transactionId: String,
        tokenSymbol: String,
        status: PendingExpressTransactionStatus,
        provider: ExpressPendingTransactionRecord.Provider
    )
}

private struct PendingExpressTransactionAnalyticsTrackerKey: InjectionKey {
    static var currentValue: PendingExpressTransactionAnalyticsTracker = CommonPendingExpressTransactionAnalyticsTracker()
}

extension InjectedValues {
    var pendingExpressTransactionAnalayticsTracker: PendingExpressTransactionAnalyticsTracker {
        get { Self[PendingExpressTransactionAnalyticsTrackerKey.self] }
        set { Self[PendingExpressTransactionAnalyticsTrackerKey.self] = newValue }
    }
}
