//
//  ExpressManagerSwappingPairRequest.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressManagerSwappingPairRequest {
    public let amountType: ExpressAmountType
    public let rateType: ExpressProviderRateType
    public let operationType: ExpressOperationType

    public var amount: Decimal {
        amountType.amount
    }

    func with(rateType: ExpressProviderRateType) -> ExpressManagerSwappingPairRequest {
        ExpressManagerSwappingPairRequest(
            amountType: amountType,
            rateType: rateType,
            operationType: operationType
        )
    }
}
