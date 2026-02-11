//
//  ExpressInteractorAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress

protocol ExpressInteractorAnalyticsLogger: ExpressAnalyticsLogger, FeeSelectorAnalytics {
    func logExpressError(_ error: Error, provider: ExpressProvider?)

    func logSwapTransactionAnalyticsEvent(destination: TokenItem)
    func logApproveTransactionAnalyticsEvent(policy: ApprovePolicy, provider: ExpressProvider, destination: TokenItem)
    func logApproveTransactionSentAnalyticsEvent(policy: ApprovePolicy, signerType: String, currentProviderHost: String)
}
