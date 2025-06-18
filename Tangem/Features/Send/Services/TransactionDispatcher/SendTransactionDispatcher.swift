//
//  SendTransactionDispatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class SendTransactionDispatcher {
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

extension SendTransactionDispatcher: TransactionDispatcher {
    func send(transaction: SendTransactionType) async throws -> TransactionDispatcherResult {
        guard case .transfer(let transferTransaction) = transaction else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        let mapper = TransactionDispatcherResultMapper()

        do {
            let hash = try await walletModel.transactionSender.send(transferTransaction, signer: transactionSigner).async()
            walletModel.updateAfterSendingTransaction()
            let signer = (transactionSigner as? TangemSigner)?.latestSigner.value
            return mapper.mapResult(hash, blockchain: walletModel.tokenItem.blockchain, signer: signer)
        } catch {
            AppLogger.error(error: error)
            throw mapper.mapError(error, transaction: transaction)
        }
    }
}
