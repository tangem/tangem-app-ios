//
//  BlockchainProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Transaction

public protocol BlockchainProvider {
    func signAndSend(_ transaction: Transaction) async throws
    func getFee(currency: Currency, amount: Decimal, destination: String) async throws -> [Decimal]
    func createTransaction(for info: TransactionInfo) throws -> Transaction
}

public struct TransactionInfo {
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
