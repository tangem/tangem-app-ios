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
    /// - Note: `private(set)` is used here only for keeping the synthesized initializer working.
    private(set) var quotesLoadingPerformanceTracker: ExpressQuotesLoadingPerformanceTracker?
}

// MARK: - Convenience extensions

extension ExpressManagerSwappingPairRequest {
    func with(rateType: ExpressProviderRateType) -> ExpressManagerSwappingPairRequest {
        ExpressManagerSwappingPairRequest(
            amountType: amountType,
            rateType: rateType,
            approvePolicy: approvePolicy,
            operationType: operationType,
            quotesLoadingPerformanceTracker: quotesLoadingPerformanceTracker
        )
    }

    func with(quotesLoadingPerformanceTracker: ExpressQuotesLoadingPerformanceTracker?) -> ExpressManagerSwappingPairRequest {
        ExpressManagerSwappingPairRequest(
            amountType: amountType,
            rateType: rateType,
            approvePolicy: approvePolicy,
            operationType: operationType,
            quotesLoadingPerformanceTracker: quotesLoadingPerformanceTracker
        )
    }
}
