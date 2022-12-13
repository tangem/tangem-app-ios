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
    case preview(expected: ExpectedSwappingResult)
    case available(expected: ExpectedSwappingResult, exchangeData: ExchangeDataModel)
    case requiredPermission(expected: ExpectedSwappingResult, approvedDataModel: ExchangeApprovedDataModel)
    case requiredRefresh(occurredError: Error)
}

public struct ExpectedSwappingResult {
    public let expectedAmount: Decimal
    public let expectedFiatAmount: Decimal
    public let fee: Decimal
    public let fiatFee: Decimal
    public let decimalCount: Int
    public let isEnoughAmountForExchange: Bool

    init(
        expectedAmount: Decimal,
        expectedFiatAmount: Decimal,
        fee: Decimal,
        fiatFee: Decimal,
        decimalCount: Int,
        isEnoughAmountForExchange: Bool
    ) {
        self.expectedAmount = expectedAmount
        self.expectedFiatAmount = expectedFiatAmount
        self.fee = fee
        self.fiatFee = fiatFee
        self.decimalCount = decimalCount
        self.isEnoughAmountForExchange = isEnoughAmountForExchange
    }
}
