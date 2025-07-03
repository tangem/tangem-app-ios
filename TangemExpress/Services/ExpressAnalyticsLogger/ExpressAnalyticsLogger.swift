//
//  ExpressAnalyticsLogger.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public protocol ExpressAnalyticsLogger {
    /// Swap
    func bestProviderSelected(_ provider: ExpressAvailableProvider)

    func logExpressError(_ error: ExpressAPIError, provider: ExpressProvider?)

    func logSwapTransactionAnalyticsEvent(destination: String?)
    func logApproveTransactionAnalyticsEvent(policy: ApprovePolicy, destination: String?)
    func logApproveTransactionSentAnalyticsEvent(policy: ApprovePolicy, signerType: String)

    // Onramp
    func logAppError(_ error: Error, provider: ExpressProvider)
    func logExpressAPIError(_ error: ExpressAPIError, provider: ExpressProvider, paymentMethod: OnrampPaymentMethod)
}
