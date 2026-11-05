//
//  SolanaGaslessTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol SolanaGaslessTransactionBuilder {
    func buildGaslessTransaction(
        _ transaction: Transaction,
        feePayer: String,
        signer: TransactionSigner
    ) async throws -> SolanaGaslessTransaction

    func buildGaslessTransaction(
        compiledTransaction: Data,
        feePayer: String,
        signer: TransactionSigner
    ) async throws -> SolanaGaslessTransaction
}

public struct SolanaGaslessTransaction: Hashable {
    public let serialized: Data
    public let lastValidBlockHeight: UInt64

    public init(serialized: Data, lastValidBlockHeight: UInt64) {
        self.serialized = serialized
        self.lastValidBlockHeight = lastValidBlockHeight
    }
}
