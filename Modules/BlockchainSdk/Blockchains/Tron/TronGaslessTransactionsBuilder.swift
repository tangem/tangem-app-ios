//
//  TronGaslessTransactionsBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct TronGaslessSignedTransactions {
    public let signedCompensationTx: String
    public let signedOriginalTx: String
}

public protocol TronGaslessTransactionsBuilder {
    func buildForGaslessSubmit(
        originalTransaction: Transaction,
        compensationTransaction: Transaction,
        signer: TransactionSigner
    ) async throws -> TronGaslessSignedTransactions
}
