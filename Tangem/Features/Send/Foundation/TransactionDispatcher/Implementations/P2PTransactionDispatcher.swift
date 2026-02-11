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
    var hasNFCInteraction: Bool {
        transactionSigner.hasNFCInteraction
    }

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        guard let stakingTransactionsSender = walletModel.p2pTransactionSender else {
            throw TransactionDispatcherResult.Error.actionNotSupported
        }

        guard case .staking(let action) = transaction else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        let transactions = try mapper.mapToP2PTransactions(action: action)
        let mapper = TransactionDispatcherResultMapper()

        do {
            let sendResults = try await stakingTransactionsSender.sendP2P(
                transactions: transactions,
                signer: transactionSigner,
                executeSend: { [apiProvider] signedTransactions in
                    try await withThrowingTaskGroup(of: (Int, String).self) { group in

                        for (index, signedTransaction) in signedTransactions.enumerated() {
                            group.addTask {
                                (
                                    index,
                                    try await apiProvider.broadcastTransaction(signedTransaction: signedTransaction)
                                )
                            }
                        }
                        var results = [(Int, String)]()

                        for try await result in group {
                            results.append(result)
                        }

                        return results
                    }
                }
            )

            let results = sendResults.map {
                mapper.mapResult(
                    $0,
                    blockchain: walletModel.tokenItem.blockchain,
                    signer: transactionSigner.latestSignerType,
                    isToken: walletModel.tokenItem.isToken
                )
            }

            guard let result = results.last else {
                throw TransactionDispatcherResult.Error.transactionNotFound
            }

            walletModel.updateAfterSendingTransaction()

            return result
        } catch {
            throw mapper.mapError(
                error.toUniversalError(),
                transaction: .staking(action)
            )
        }
    }
}
