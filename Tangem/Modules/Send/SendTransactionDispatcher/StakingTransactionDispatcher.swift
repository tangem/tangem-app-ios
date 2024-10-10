//
//  StakingTransactionDispatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdkLocal
import TangemStaking

class StakingTransactionDispatcher {
    private let walletModel: WalletModel
    private let transactionSigner: TangemSigner
    private let pendingHashesSender: StakingPendingHashesSender
    private let stakingTransactionMapper: StakingTransactionMapper

    private var stuck: DispatchProgressStuck? = .none

    init(
        walletModel: WalletModel,
        transactionSigner: TangemSigner,
        pendingHashesSender: StakingPendingHashesSender,
        stakingTransactionMapper: StakingTransactionMapper
    ) {
        self.walletModel = walletModel
        self.transactionSigner = transactionSigner
        self.pendingHashesSender = pendingHashesSender
        self.stakingTransactionMapper = stakingTransactionMapper
    }
}

// MARK: - SendTransactionDispatcher

extension StakingTransactionDispatcher: SendTransactionDispatcher {
    func send(transaction: SendTransactionType) async throws -> SendTransactionDispatcherResult {
        guard case .staking(let action) = transaction else {
            throw SendTransactionDispatcherResult.Error.transactionNotFound
        }

        let mapper = SendTransactionMapper()
        do {
            switch stuck?.type {
            case .none:
                return try await sendStakeKit(action: action)

            case .send(let transaction):
                let index = action.transactions.firstIndex(where: { $0.id == transaction.id })
                let transactionDispatcherResult = try await sendStakeKit(action: action, offset: index)
                stuck = .none
                return transactionDispatcherResult
            }
        } catch {
            throw mapper.mapError(error, transaction: transaction)
        }
    }
}

// MARK: - Private

private extension StakingTransactionDispatcher {
    func stakeKitTransactionSender() throws -> StakeKitTransactionSender {
        guard let stakeKitTransactionSender = walletModel.stakeKitTransactionSender else {
            throw Errors.stakingUnsupported
        }

        return stakeKitTransactionSender
    }

    func sendStakeKit(action: StakingTransactionAction, offset: Int? = .none) async throws -> SendTransactionDispatcherResult {
        let sender = try stakeKitTransactionSender()
        var transactions = stakingTransactionMapper.mapToStakeKitTransactions(action: action)

        if let offset {
            transactions = Array(transactions[offset...])
        }

        let stream = sender.sendStakeKit(transactions: transactions, signer: transactionSigner, delay: 5)

        var transactionDispatcherResult: SendTransactionDispatcherResult?

        do {
            for try await result in stream {
                transactionDispatcherResult = try await sendHash(action: action, result: result)
            }
        } catch let error as StakeKitTransactionSendError {
            stuck = .init(action: action, type: .send(transaction: error.transaction))
            throw error.error
        } catch {
            throw error
        }

        guard let transactionDispatcherResult else {
            throw Errors.resultNotFound
        }

        walletModel.updateAfterSendingTransaction()
        return transactionDispatcherResult
    }

    func sendHash(action: StakingTransactionAction, result: StakeKitTransactionSendResult) async throws -> SendTransactionDispatcherResult {
        let hash = StakingPendingHash(transactionId: result.transaction.id, hash: result.result.hash)
        try? await pendingHashesSender.sendHash(hash)

        let signer = transactionSigner.latestSigner.value
        return SendTransactionMapper().mapResult(result.result, blockchain: walletModel.blockchainNetwork.blockchain, signer: signer)
    }
}

extension StakingTransactionDispatcher {
    struct DispatchProgressStuck: Hashable {
        let action: StakingTransactionAction
        let type: StuckType

        enum StuckType: Hashable {
            case send(transaction: StakeKitTransaction)
        }
    }

    enum Errors: Error {
        case stakingUnsupported
        case resultNotFound
    }
}
