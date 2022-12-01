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
    public let gasPrice: String
    public let destinationAddress: String
    public let sourceAddress: String
    public let txData: Data
    public let fromTokenAmount: String
    public let toTokenAmount: String
    public let fromTokenAddress: String?
    public let toTokenAddress: String?

    public init(
        gas: Int,
        gasPrice: String,
        destinationAddress: String,
        sourceAddress: String,
        txData: Data,
        fromTokenAmount: String,
        toTokenAmount: String,
        fromTokenAddress: String? = nil,
        toTokenAddress: String? = nil
    ) {
        self.gas = gas
        self.gasPrice = gasPrice
        self.destinationAddress = destinationAddress
        self.sourceAddress = sourceAddress
        self.txData = txData
        self.fromTokenAmount = fromTokenAmount
        self.toTokenAmount = toTokenAmount
        self.fromTokenAddress = fromTokenAddress
        self.toTokenAddress = toTokenAddress
    }

    public init(exchangeData: ExchangeData) {
        gas = exchangeData.tx.gas
        gasPrice = exchangeData.tx.gasPrice
        destinationAddress = exchangeData.tx.to
        sourceAddress = exchangeData.tx.from
        txData = Data(hexString: exchangeData.tx.data)
        fromTokenAmount = exchangeData.fromTokenAmount
        toTokenAmount = exchangeData.toTokenAmount
        fromTokenAddress = exchangeData.fromToken.address
        toTokenAddress = exchangeData.toToken.address
    }
}
