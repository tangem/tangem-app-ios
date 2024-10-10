//
//  DemoSendTransactionDispatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdkLocal

class DemoSendTransactionDispatcher {
    private let walletModel: WalletModel
    private let transactionSigner: TransactionSigner

    init(
        walletModel: WalletModel,
        transactionSigner: TransactionSigner
    ) {
        self.walletModel = walletModel
        self.transactionSigner = transactionSigner
    }
}

// MARK: - SendTransactionDispatcher

extension DemoSendTransactionDispatcher: SendTransactionDispatcher {
    func send(transaction: SendTransactionType) async throws -> SendTransactionDispatcherResult {
        guard case .transfer = transaction else {
            throw SendTransactionDispatcherResult.Error.transactionNotFound
        }

        let hash = Data.randomData(count: 32)

        do {
            _ = try await transactionSigner
                .sign(hash: hash, walletPublicKey: walletModel.wallet.publicKey)
                .mapSendError(tx: hash.hexString)
                .async()
        } catch {
            throw SendTransactionMapper().mapError(error, transaction: transaction)
        }

        throw SendTransactionDispatcherResult.Error.demoAlert
    }
}
