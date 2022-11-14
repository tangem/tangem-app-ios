//
//  ExchangeManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol ExchangeManager {
    var walletAddress: String { get }

    func send(_ tx: Transaction, signer: TangemSigner) async throws
    func getFee(currency: Currency, destination: String) async throws -> [Currency]
    func createTransaction(for currency: Currency,
                           fee: Decimal,
                           destinationAddress: String,
                           sourceAddress: String?,
                           changeAddress: String?) throws -> Transaction
}

extension ExchangeManager {
    func createTransaction(for currency: Currency,
                           fee: Decimal,
                           destinationAddress: String,
                           sourceAddress: String? = nil,
                           changeAddress: String? = nil) throws -> Transaction {
        try self.createTransaction(for: currency,
                                   fee: fee,
                                   destinationAddress: destinationAddress,
                                   sourceAddress: sourceAddress,
                                   changeAddress: changeAddress)
    }
}
