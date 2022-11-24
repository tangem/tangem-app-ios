//
//  BlockchainNetworkProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Transaction

public protocol BlockchainNetworkProvider {
//    func getBalance() -> Decimal
    func signAndSend(_ transaction: Transaction) async throws
    func getFee(currency: Currency, amount: Decimal, destination: String) async throws -> [Decimal]
    func createTransaction(for info: ExchangeTransactionInfo) throws -> Transaction
}
