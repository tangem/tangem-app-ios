//
//  P2PTransactionDispatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import BlockchainSdk

final class P2PTransactionDispatcher {
    private let walletModel: any WalletModel
    private let transactionSigner: TangemSigner
    private let apiProvider: P2PAPIProvider
    private let mapper: StakingTransactionMapper

    init(
        walletModel: any WalletModel,
        transactionSigner: TangemSigner,
        mapper: StakingTransactionMapper,
        apiProvider: P2PAPIProvider
    ) {
        self.walletModel = walletModel
        self.transactionSigner = transactionSigner
        self.mapper = mapper
        self.apiProvider = apiProvider
    }
}

extension P2PTransactionDispatcher: TransactionDispatcher {
    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        guard let stakingTransactionsBuilder = walletModel.stakingTransactionsBuilder else {
            throw TransactionDispatcherResult.Error.actionNotSupported
        }

        guard case .staking(let action) = transaction else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        let transactions = mapper.mapToP2PTransactions(action: action)

        let signResults = try await stakingTransactionsBuilder.buildRawTransactions(
            from: transactions,
            publicKey: walletModel.publicKey,
            signer: transactionSigner
        )

        guard let signedTransaction = signResults.first as? String else {
            throw BlockchainSdkError.failedToSendTx
        }

        let hash = try await apiProvider.broadcastTransaction(signedTransaction: signedTransaction)
        let result = TransactionDispatcherResult(hash: hash, url: nil, signerType: "", currentHost: "")

        walletModel.updateAfterSendingTransaction()

        return result
    }
}
