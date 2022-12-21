//
//  PreviewSwappingDataModel.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct PreviewSwappingDataModel {
    public let expectedAmount: Decimal
    public let expectedFiatAmount: Decimal
    public let isPermissionRequired: Bool
    public let isEnoughAmountForExchange: Bool

    public init(
        expectedAmount: Decimal,
        expectedFiatAmount: Decimal,
        isPermissionRequired: Bool,
        isEnoughAmountForExchange: Bool
    ) {
        self.expectedAmount = expectedAmount
        self.expectedFiatAmount = expectedFiatAmount
        self.isPermissionRequired = isPermissionRequired
        self.isEnoughAmountForExchange = isEnoughAmountForExchange
    }
}
