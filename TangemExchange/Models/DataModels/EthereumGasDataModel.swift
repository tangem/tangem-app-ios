//
//  EthereumGasDataModel.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct EthereumGasDataModel {
    public let currency: Currency
    public let gasPrice: Int
    public let gasLimit: Int

    /// Calculated estimated fee
    public var fee: Decimal {
        currency.convertFromWEI(value: Decimal(gasPrice * gasLimit))
    }

    public init(currency: Currency, gasPrice: Int, gasLimit: Int) {
        self.currency = currency
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
    }
}
