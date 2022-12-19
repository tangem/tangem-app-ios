//
//  ExpectedSwappingResult.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpectedSwappingResult {
    public let expectedAmount: Decimal
    public let expectedFiatAmount: Decimal
    public let feeFiatRate: Decimal
    public let isEnoughAmountForExchange: Bool
    public let isEnoughAmountForFee: Bool
    public let isRequiredPermission: Bool

    init(
        expectedAmount: Decimal,
        expectedFiatAmount: Decimal,
        feeFiatRate: Decimal,
        isEnoughAmountForExchange: Bool,
        isEnoughAmountForFee: Bool,
        isRequiredPermission: Bool
    ) {
        self.expectedAmount = expectedAmount
        self.expectedFiatAmount = expectedFiatAmount
        self.feeFiatRate = feeFiatRate
        self.isEnoughAmountForExchange = isEnoughAmountForExchange
        self.isEnoughAmountForFee = isEnoughAmountForFee
        self.isRequiredPermission = isRequiredPermission
    }
}
