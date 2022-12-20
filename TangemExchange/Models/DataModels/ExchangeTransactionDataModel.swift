//
//  ExchangeTransactionDataModel.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct ExchangeTransactionDataModel {
    public let sourceCurrency: Currency
    public let destinationCurrency: Currency

    public let sourceAddress: String
    public let destinationAddress: String

    /// Tx data which will be used as  etherium data in transaction
    public let txData: Data

    /// Amount to send in WEI
    public let amount: Decimal

    /// A long value gas, usual in period from 21000 to 30000
    public let gasValue: Int

    /// Gas price in WEI which will be used for calculate estimated fee
    public let gasPrice: Int

    /// Calculated estimated fee
    public var fee: Decimal {
        switch sourceCurrency.currencyType {
        case .coin:
            return sourceCurrency.convertFromWEI(value: Decimal(gasValue * gasPrice))
        case .token:
            let decimalValue = pow(10, sourceCurrency.blockchain.decimalCount)
            return Decimal(gasValue * gasPrice) / decimalValue
        }
    }

    public init(
        sourceCurrency: Currency,
        destinationCurrency: Currency,
        sourceAddress: String,
        destinationAddress: String,
        txData: Data,
        amount: Decimal,
        gasValue: Int,
        gasPrice: Int
    ) {
        self.sourceCurrency = sourceCurrency
        self.destinationCurrency = destinationCurrency
        self.sourceAddress = sourceAddress
        self.destinationAddress = destinationAddress
        self.txData = txData
        self.amount = amount
        self.gasValue = gasValue
        self.gasPrice = gasPrice
    }
}
