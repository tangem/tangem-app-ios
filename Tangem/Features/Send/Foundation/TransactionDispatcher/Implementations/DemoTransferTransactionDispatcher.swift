//
//  DemoTransferTransactionDispatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

class DemoTransferTransactionDispatcher {
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

extension DemoTransferTransactionDispatcher: TransactionDispatcher {
    var hasNFCInteraction: Bool {
        true
    }

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        let hash = Data.randomData(count: 32)
        let mapper = TransactionDispatcherResultMapper()

        do {
            _ = try await transactionSigner
                .sign(hash: hash, walletPublicKey: walletModel.publicKey)
                .mapAndEraseSendTxError(tx: hash.hexString)
                .async()
        } catch {
            throw mapper.mapError(error.toUniversalError(), transaction: transaction)
        }

        // At the end show demo alert for user
        throw TransactionDispatcherResult.Error.demoAlert
    }
}
