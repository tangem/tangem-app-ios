//
//  ExchangeTransactionDataModel+Mock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemExchange

extension ExchangeTransactionDataModel {
    static let mock = ExchangeTransactionDataModel(
        sourceCurrency: .mock,
        sourceBlockchain: .ethereum,
        destinationCurrency: .mock,
        sourceAddress: "",
        destinationAddress: "",
        txData: Data(),
        sourceAmount: 123_000_000_000_000,
        destinationAmount: 300_000_000_000_000,
        value: 0,
        gasValue: 21000,
        gasPrice: 15_000_000_000
    )
}
