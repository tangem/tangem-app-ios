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
    public let expectedAmount: Decimal
    public let expectedFiatAmount: Decimal
    public let expectedFee: Decimal
    public let expectedFiatFee: Decimal
    
    public let isEnoughAmountForFee: Bool
    public let isRequiredPermission: Bool
    public let transactionInfo: ExchangeTransactionDataModel
    
    public init(
        expectedAmount: Decimal,
        expectedFiatAmount: Decimal,
        expectedFee: Decimal,
        expectedFiatFee: Decimal,
        isEnoughAmountForFee: Bool,
        isRequiredPermission: Bool,
        transactionInfo: ExchangeTransactionDataModel
    ) {
        self.expectedAmount = expectedAmount
        self.expectedFiatAmount = expectedFiatAmount
        self.expectedFee = expectedFee
        self.expectedFiatFee = expectedFiatFee
        self.isEnoughAmountForFee = isEnoughAmountForFee
        self.isRequiredPermission = isRequiredPermission
        self.transactionInfo = transactionInfo
    }
}
