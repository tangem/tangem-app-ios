//
//  ExchangeTransactionInfo+Mock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemExchange

extension ExchangeTransactionInfo {
    static let mock = ExchangeTransactionInfo(
        currency: .mock,
        source: "",
        destination: "",
        amount: 0,
        fee: 0,
        oneInchTxData: Data()
    )
}
