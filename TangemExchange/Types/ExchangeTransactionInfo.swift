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
    public let amount: Decimal
    public let fee: Decimal
    public let destination: String
    public let sourceAddress: String?
    public let changeAddress: String?

    public init(
        currency: Currency,
        amount: Decimal,
        fee: Decimal,
        destination: String,
        sourceAddress: String? = nil,
        changeAddress: String? = nil
    ) {
        self.currency = currency
        self.amount = amount
        self.fee = fee
        self.destination = destination
        self.sourceAddress = sourceAddress
        self.changeAddress = changeAddress
    }
}
