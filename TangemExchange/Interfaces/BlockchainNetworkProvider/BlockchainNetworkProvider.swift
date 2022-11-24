//
//  BlockchainNetworkProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import struct BlockchainSdk.Transaction

public protocol TransactionBuilder {
    associatedtype Transaction

    func buildTransaction(for info: SwapTransactionInfo, fee: Decimal) throws -> Transaction
    func sign(_ transaction: Transaction) async throws -> Transaction
    func send(_ transaction: Transaction) async throws
}

public protocol BlockchainInfoProvider {
    func getBalance(currency: Currency) async throws -> Decimal
    func getFee(currency: Currency, amount: Decimal, destination: String) async throws -> [Decimal]
}
