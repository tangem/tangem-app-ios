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
import TangemFoundation

class SendTransactionDispatcher {
    private let walletModel: any WalletModel
    private let transactionSigner: TangemSigner

    init(
        walletModel: any WalletModel,
        transactionSigner: TangemSigner
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

            return mapper.mapResult(
                hash,
                blockchain: walletModel.tokenItem.blockchain,
                signer: transactionSigner.latestSignerType
            )
        } catch {
            AppLogger.error(error: error)
            throw mapper.mapError(error.toUniversalError(), transaction: transaction)
        }
    }
}
