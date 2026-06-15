//
//  ExpressAnalyticsLogger.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public typealias ExpressAnalyticsLogger = TangemExpress.AnalyticsLogger

public protocol AnalyticsLogger {
    /// Swap
    func bestProviderSelected(_ provider: ExpressAvailableProvider)
    func logGasEstimationOverrideError(_ error: Error)

    // Onramp
    func logAppError(_ error: Error, provider: ExpressProvider)
    func logExpressAPIError(_ error: ExpressAPIError, provider: ExpressProvider, paymentMethod: OnrampPaymentMethod)
}
