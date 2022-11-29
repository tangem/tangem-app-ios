//
//  ExchangeSwapDataModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct ExchangeSwapDataModel {
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

    public init(swapData: SwapData) {
        gas = swapData.tx.gas
        gasPrice = swapData.tx.gasPrice
        destinationAddress = swapData.tx.to
        sourceAddress = swapData.tx.from
        txData = Data(hexString: swapData.tx.data)
        fromTokenAmount = swapData.fromTokenAmount
        toTokenAmount = swapData.toTokenAmount
        fromTokenAddress = swapData.fromToken.address
        toTokenAddress = swapData.toToken.address
    }
}
