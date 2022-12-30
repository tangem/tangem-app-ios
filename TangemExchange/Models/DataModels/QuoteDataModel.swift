//
//  QuoteDataModel.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct QuoteDataModel {
    /// WEI
    public let toTokenAmount: Decimal
    /// WEI
    public let fromTokenAmount: Decimal
    public let estimatedGas: Int

    public init(quoteData: QuoteData) throws {
        guard let toTokenAmount = Decimal(string: quoteData.toTokenAmount),
              let fromTokenAmount = Decimal(string: quoteData.fromTokenAmount) else {
            throw OneInchExchangeProvider.Errors.incorrectDataFormat
        }

        self.toTokenAmount = toTokenAmount
        self.fromTokenAmount = fromTokenAmount
        self.estimatedGas = quoteData.estimatedGas
    }
}
