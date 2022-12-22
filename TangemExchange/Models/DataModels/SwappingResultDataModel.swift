//
//  SwappingResultDataModel.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct SwappingResultDataModel {
    public let amount: Decimal
    public let fiatAmount: Decimal
    public let fee: Decimal
    public let fiatFee: Decimal

    public let isEnoughAmountForExchange: Bool
    public let isEnoughAmountForFee: Bool
    public let isPermissionRequired: Bool

    public init(
        amount: Decimal,
        fiatAmount: Decimal,
        fee: Decimal,
        fiatFee: Decimal,
        isEnoughAmountForExchange: Bool,
        isEnoughAmountForFee: Bool,
        isPermissionRequired: Bool
    ) {
        self.amount = amount
        self.fiatAmount = fiatAmount
        self.fee = fee
        self.fiatFee = fiatFee
        self.isEnoughAmountForExchange = isEnoughAmountForExchange
        self.isEnoughAmountForFee = isEnoughAmountForFee
        self.isPermissionRequired = isPermissionRequired
    }
}
