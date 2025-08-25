//
//  DemoSendTransactionDispatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

class DemoSendTransactionDispatcher {
    private let walletModel: any WalletModel
    private let transactionSigner: TransactionSigner

    init(
        walletModel: any WalletModel,
        transactionSigner: TransactionSigner
    ) {
        self.walletModel = walletModel
        self.transactionSigner = transactionSigner
    }
}

// MARK: - TransactionDispatcher

extension DemoSendTransactionDispatcher: TransactionDispatcher {
    func send(transaction: SendTransactionType) async throws -> TransactionDispatcherResult {
        guard case .transfer = transaction else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        let hash = Data.randomData(count: 32)

        do {
            _ = try await transactionSigner
                .sign(hash: hash, walletPublicKey: walletModel.publicKey)
                .mapAndEraseSendTxError(tx: hash.hexString)
                .async()
        } catch {
            throw TransactionDispatcherResultMapper().mapError(error.toUniversalError(), transaction: transaction)
        }

        throw TransactionDispatcherResult.Error.demoAlert
    }
}
