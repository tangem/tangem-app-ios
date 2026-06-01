//
//  ExpressManagerSwappingPairRequest.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public struct ExpressManagerSwappingPairRequest {
    public let amountType: ExpressAmountType
    public let rateType: ExpressProviderRateType
    public let approvePolicy: ApprovePolicy
    public let operationType: ExpressOperationType

    public var amount: Decimal {
        amountType.amount
    }

    /// - Note: Stays nil for single-provider updates since quotes loading performance tracking
    /// is only relevant for batched updates of multiple providers.
    /// - Note: `private(set) var` (rather than `let`) is required so the synthesized memberwise
    /// initializer treats this optional as `= nil` by default; otherwise call sites that don't
    /// pass a tracker fail to compile.
    private(set) var quotesLoadingPerformanceTracker: ExpressQuotesLoadingPerformanceTracker?
}
