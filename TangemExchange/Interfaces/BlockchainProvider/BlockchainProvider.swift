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
//    func getBlockchain() -> Blockchain
    func signAndSend(_ transaction: Transaction) async throws
    func getFee(currency: Currency, amount: Decimal, destination: String) async throws -> [Decimal]
    func createTransaction(for info: TransactionInfo) throws -> Transaction
}

public extension BlockchainProvider {
    func createTransaction(for currency: Currency,
                           amount: Decimal,
                           fee: Decimal,
                           destination: String,
                           sourceAddress: String? = nil,
                           changeAddress: String? = nil) throws -> Transaction {
        let info = TransactionInfo(currency: currency, amount: amount, fee: fee, destination: destination)
        return try self.createTransaction(for: info)
    }
}

struct TransactionInfo {
    let currency: Currency
    let amount: Decimal
    let fee: Decimal
    let destination: String
    let sourceAddress: String?
    let changeAddress: String?
    
    init(
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
