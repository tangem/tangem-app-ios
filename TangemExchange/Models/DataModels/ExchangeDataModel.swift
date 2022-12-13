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
    /// GWEI
    public let gasPrice: Int
    public let txData: Data

    public let destinationAddress: String
    public let sourceAddress: String
    public let fromTokenAmount: Decimal
    public let toTokenAmount: Decimal

    /// contract?
    public let fromTokenAddress: String?
    /// contract?
    public let toTokenAddress: String?

    public init(exchangeData: ExchangeData) throws {
        guard let gasPrice = Int(exchangeData.tx.gasPrice),
              let fromTokenAmount = Decimal(string: exchangeData.fromTokenAmount),
              let toTokenAmount = Decimal(string: exchangeData.toTokenAmount) else {
            throw ExchangeInchError.incorrectData
        }

        self.gas = exchangeData.tx.gas
        self.gasPrice = gasPrice
        self.fromTokenAmount = fromTokenAmount
        self.toTokenAmount = toTokenAmount

        txData = Data(hexString: exchangeData.tx.data)
        destinationAddress = exchangeData.tx.to
        sourceAddress = exchangeData.tx.from
        fromTokenAddress = exchangeData.fromToken.address
        toTokenAddress = exchangeData.toToken.address
    }
}
