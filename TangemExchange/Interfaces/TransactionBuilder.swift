//
//  TransactionBuilder.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public protocol TransactionBuilder {
    associatedtype Transaction

    func buildTransaction(for info: SwapTransactionInfo, fee: Decimal) throws -> Transaction
    func sign(_ transaction: Transaction) async throws -> Transaction
    func send(_ transaction: Transaction) async throws
}
