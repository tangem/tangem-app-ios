//
//  ExpectedSwappingResult.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct PreviewSwappingDataModel {
    public let expectedAmount: Decimal
    public let expectedFiatAmount: Decimal
    public let isEnoughAmountForExchange: Bool

    public init(
        expectedAmount: Decimal,
        expectedFiatAmount: Decimal,
        isEnoughAmountForExchange: Bool
    ) {
        self.expectedAmount = expectedAmount
        self.expectedFiatAmount = expectedFiatAmount
        self.isEnoughAmountForExchange = isEnoughAmountForExchange
    }
}

public struct SwappingResultDataModel {
    public let amount: Decimal
    public let fiatAmount: Decimal
    public let fee: Decimal
    public let fiatFee: Decimal
    
    public let isEnoughAmountForExchange: Bool
    public let isEnoughAmountForFee: Bool
    public let isRequiredPermission: Bool
    
    public init(
        amount: Decimal,
        fiatAmount: Decimal,
        fee: Decimal,
        fiatFee: Decimal,
        isEnoughAmountForExchange: Bool,
        isEnoughAmountForFee: Bool,
        isRequiredPermission: Bool
    ) {
        self.amount = amount
        self.fiatAmount = fiatAmount
        self.fee = fee
        self.fiatFee = fiatFee
        self.isEnoughAmountForExchange = isEnoughAmountForExchange
        self.isEnoughAmountForFee = isEnoughAmountForFee
        self.isRequiredPermission = isRequiredPermission
    }
}
