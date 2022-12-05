//
//  ExchangeAvailabilityState.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public enum ExchangeAvailabilityState {
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
    public let fiatFee: Decimal
    public let decimalCount: Int
    public let isEnoughAmountForExchange: Bool

    init(
        expectAmount: Decimal,
        expectFiatAmount: Decimal,
        fee: Decimal,
        fiatFee: Decimal,
        decimalCount: Int,
        isEnoughAmountForExchange: Bool
    ) {
        self.expectAmount = expectAmount
        self.expectFiatAmount = expectFiatAmount
        self.fee = fee
        self.fiatFee = fiatFee
        self.decimalCount = decimalCount
        self.isEnoughAmountForExchange = isEnoughAmountForExchange
    }
}
