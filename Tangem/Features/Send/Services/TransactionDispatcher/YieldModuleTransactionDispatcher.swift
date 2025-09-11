//
//  YieldModuleTransactionDispatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

class YieldModuleTransactionDispatcher {
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

extension YieldModuleTransactionDispatcher: TransactionDispatcher {
    func send(transaction: SendTransactionType) async throws -> TransactionDispatcherResult {
        let results = try await send(transactions: [transaction])
        guard let result = results.first else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }
        
        return result
    }

    func send(transactions: [SendTransactionType]) async throws -> [TransactionDispatcherResult] {
        let transferTransactions = transactions.compactMap { transactionType -> BSDKTransaction? in
            switch transactionType {
            case .staking: return nil
            case .transfer(let transaction): return transaction
            }
        }

        guard !transferTransactions.isEmpty else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        let mapper = TransactionDispatcherResultMapper()

        do {
            let hashes = try await walletModel.transactionSender.send(
                transferTransactions,
                signer: transactionSigner
            ).async()
            walletModel.updateAfterSendingTransaction()

            return hashes.map { hash in
                mapper.mapResult(
                    hash,
                    blockchain: walletModel.tokenItem.blockchain,
                    signer: transactionSigner.latestSignerType
                )
            }
        } catch {
            AppLogger.error(error: error)
            throw error.toUniversalError()
        }
    }
}
