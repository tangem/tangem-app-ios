//
//  QuoteDataModel.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct QuoteDataModel {
    /// GWEI
    public let toTokenAmount: Decimal
    /// GWEI
    public let fromTokenAmount: Decimal
    public let estimatedGas: Int

    public init(quoteData: QuoteData) throws {
        guard let toTokenAmount = Decimal(string: quoteData.toTokenAmount),
              let fromTokenAmount = Decimal(string: quoteData.fromTokenAmount) else {
            throw ExchangeInchError.incorrectData
        }

        self.toTokenAmount = toTokenAmount
        self.fromTokenAmount = fromTokenAmount
        self.estimatedGas = quoteData.estimatedGas
    }
}
