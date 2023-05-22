//
//  SwappingAvailabilityModel.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct SwappingAvailabilityModel {
    public let isEnoughAmountForSwapping: Bool
    public let isEnoughAmountForFee: Bool
    public let isPermissionRequired: Bool
    public let transactionData: SwappingTransactionData
    public let gasOptions: [EthereumGasDataModel]

    public var destinationAmount: Decimal {
        transactionData.destinationCurrency.convertFromWEI(
            value: transactionData.destinationAmount
        )
    }

    public init(
        isEnoughAmountForSwapping: Bool,
        isEnoughAmountForFee: Bool,
        isPermissionRequired: Bool,
        transactionData: SwappingTransactionData,
        gasOptions: [EthereumGasDataModel]
    ) {
        self.isEnoughAmountForSwapping = isEnoughAmountForSwapping
        self.isEnoughAmountForFee = isEnoughAmountForFee
        self.isPermissionRequired = isPermissionRequired
        self.transactionData = transactionData
        self.gasOptions = gasOptions
    }
}
