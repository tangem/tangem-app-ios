//
//  YieldModuleTransactionDispatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class YieldModuleTransactionDispatcher {
    private let blockchain: Blockchain
    private let walletModelUpdater: WalletModelUpdater
    private let transactionSigner: TangemSigner
    private let transactionsSender: MultipleTransactionsSender
    private let logger: YieldAnalyticsLogger

    init(
        blockchain: Blockchain,
        walletModelUpdater: WalletModelUpdater,
        transactionsSender: MultipleTransactionsSender,
        transactionSigner: TangemSigner,
        logger: YieldAnalyticsLogger
    ) {
        self.blockchain = blockchain
        self.walletModelUpdater = walletModelUpdater
        self.transactionsSender = transactionsSender
        self.transactionSigner = transactionSigner
        self.logger = logger
    }
}

// MARK: - TransactionDispatcher

extension YieldModuleTransactionDispatcher: TransactionDispatcher {
    var hasNFCInteraction: Bool {
        transactionSigner.hasNFCInteraction
    }

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        let results = try await send(transactions: [transaction])
        guard let result = results.first else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        return result
    }

    func send(transactions: [TransactionDispatcherTransactionType]) async throws -> [TransactionDispatcherResult] {
        let transferTransactions = transactions.compactMap { transactionType -> BSDKTransaction? in
            switch transactionType {
            case .staking, .express: return nil
            case .transfer(let transaction): return transaction
            }
        }

        guard let firstTransaction = transferTransactions.first else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        let mapper = TransactionDispatcherResultMapper()

        do {
            let hashes = try await transactionsSender.send(
                transferTransactions,
                signer: transactionSigner
            ).async()

            walletModelUpdater.updateAfterSendingTransaction()

            let sentTransactionResults = hashes.map { hash in
                mapper.mapResult(
                    hash,
                    blockchain: blockchain,
                    signer: transactionSigner.latestSignerType
                )
            }

            sentTransactionResults.forEach {
                logger.logTransactionSent(with: $0)
            }

            return sentTransactionResults
        } catch {
            AppLogger.error(error: error)
            // [REDACTED_TODO_COMMENT]
            throw mapper.mapError(error.toUniversalError(), transaction: .transfer(firstTransaction))
        }
    }
}
