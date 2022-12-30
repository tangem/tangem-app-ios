//
//  ExchangeDataModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct ExchangeDataModel {
    public let gas: Int
    /// WEI
    public let gasPrice: Int
    public let txData: Data

    public let sourceAddress: String
    public let destinationAddress: String

    /// WEI
    public let sourceTokenAmount: Decimal
    /// WEI
    public let destinationTokenAmount: Decimal

    /// Contract address
    public let sourceTokenAddress: String?
    /// Contract address
    public let destinationTokenAddress: String?

    public init(exchangeData: ExchangeData) throws {
        guard let gasPrice = Int(exchangeData.tx.gasPrice),
              let fromTokenAmount = Decimal(string: exchangeData.fromTokenAmount),
              let toTokenAmount = Decimal(string: exchangeData.toTokenAmount) else {
            throw OneInchExchangeProvider.Errors.incorrectDataFormat
        }

        self.gas = exchangeData.tx.gas
        self.gasPrice = gasPrice
        self.sourceTokenAmount = fromTokenAmount
        self.destinationTokenAmount = toTokenAmount

        txData = Data(hexString: exchangeData.tx.data)
        sourceAddress = exchangeData.tx.from
        destinationAddress = exchangeData.tx.to
        sourceTokenAddress = exchangeData.fromToken.address
        destinationTokenAddress = exchangeData.toToken.address
    }
}
