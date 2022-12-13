//
//  ExchangeTransactionInfo.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct ExchangeTransactionInfo {
    public let currency: Currency
    public let source: String
    public let destination: String
    public let amount: Decimal
    public let fee: Decimal
    public let oneInchTxData: Data

    public init(
        currency: Currency,
        source: String,
        destination: String,
        amount: Decimal,
        fee: Decimal,
        oneInchTxData: Data
    ) {
        self.currency = currency
        self.source = source
        self.destination = destination
        self.amount = amount
        self.fee = fee
        self.oneInchTxData = oneInchTxData
    }
}
