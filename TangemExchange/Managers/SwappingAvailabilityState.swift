//
//  SwappingAvailabilityState.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public enum SwappingAvailabilityState {
    case idle
    case loading
    case available(swappingResult: ExpectSwappingResult)
    case requiredPermission(swappingResult: ExpectSwappingResult)
    case requiredRefresh(occurredError: Error)
}

public struct ExpectSwappingResult {
    public let expectAmount: Decimal
    public let expectFiatAmount: Decimal
    public let fee: Decimal
    public let decimalCount: Int

    init(
        expectAmount: Decimal,
        expectFiatAmount: Decimal,
        fee: Decimal,
        decimalCount: Int
    ) {
        self.expectAmount = expectAmount
        self.expectFiatAmount = expectFiatAmount
        self.fee = fee
        self.decimalCount = decimalCount
    }
}
