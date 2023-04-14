//
//  SwappingDataModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct SwappingDataModel {
    public let sourceAddress: String
    public let destinationAddress: String

    /// WEI
    public let value: Decimal
    public let txData: Data

    /// WEI
    public let sourceCurrencyAmount: Decimal
    public let destinationCurrencyAmount: Decimal

    /// Contract address
    public let sourceTokenAddress: String?
    /// Contract address
    public let destinationTokenAddress: String?

    public init(swappingData: SwappingData) throws {
        guard let sourceCurrencyAmount = Decimal(string: swappingData.fromTokenAmount),
              let destinationCurrencyAmount = Decimal(string: swappingData.toTokenAmount),
              let value = Decimal(string: swappingData.tx.value) else {
            throw OneInchSwappingProvider.Errors.incorrectDataFormat
        }

        self.sourceCurrencyAmount = sourceCurrencyAmount
        self.destinationCurrencyAmount = destinationCurrencyAmount
        self.value = value

        txData = Data(hexString: swappingData.tx.data)
        sourceAddress = swappingData.tx.from
        destinationAddress = swappingData.tx.to
        sourceTokenAddress = swappingData.fromToken.address
        destinationTokenAddress = swappingData.toToken.address
    }
}
