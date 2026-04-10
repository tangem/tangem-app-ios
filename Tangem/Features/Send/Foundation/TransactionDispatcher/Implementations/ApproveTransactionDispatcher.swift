//
//  ApproveTransactionDispatcher.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation
import TangemExpress

final class ApproveTransactionDispatcher {
    private let walletModel: any WalletModel
    private let transactionSigner: TangemSigner
    private let transferTransactionDispatcher: TransactionDispatcher

    private var feeTokenItem: TokenItem { walletModel.feeTokenItem }
    private var transactionCreator: TransactionCreator { walletModel.transactionCreator }

    init(
        walletModel: any WalletModel,
        transactionSigner: TangemSigner,
        transferTransactionDispatcher: TransactionDispatcher
    ) {
        self.walletModel = walletModel
        self.transactionSigner = transactionSigner
        self.transferTransactionDispatcher = transferTransactionDispatcher
    }
}

// MARK: - TransactionDispatcher

extension ApproveTransactionDispatcher: TransactionDispatcher {
    var hasNFCInteraction: Bool {
        transactionSigner.hasNFCInteraction
    }

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        guard case .approve(let data, let fee) = transaction else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        let transaction = try await buildTransaction(data: data, fee: fee)
        return try await transferTransactionDispatcher.send(transaction: .transfer(transaction))
    }

    /// Sends multiple approve transactions in a single signing session (e.g. revoke+approve for USDT).
    func send(transactions: [TransactionDispatcherTransactionType]) async throws -> [TransactionDispatcherResult] {
        guard !transactions.isEmpty else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        guard transactions.count > 1 else {
            return [try await send(transaction: transactions[0])]
        }

        let approveTransactions = transactions.compactMap { transactionType -> (data: ApproveTransactionData, fee: BSDKFee)? in
            guard case .approve(let data, let fee) = transactionType else { return nil }
            return (data, fee)
        }

        guard approveTransactions.count == transactions.count else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        var builtTransactions = [BSDKTransaction]()
        for tx in approveTransactions {
            let built = try await buildTransaction(data: tx.data, fee: tx.fee)
            builtTransactions.append(built)
        }

        guard let multipleTransactionsSender = walletModel.multipleTransactionsSender else {
            throw TransactionDispatcherProviderError.transactionNotSupported(reason: "MultipleTransactionsSender is not available")
        }

        let mapper = TransactionDispatcherResultMapper()

        do {
            let hashes = try await multipleTransactionsSender.send(
                builtTransactions,
                signer: transactionSigner
            ).async()

            return hashes.map { hash in
                mapper.mapResult(
                    hash,
                    blockchain: feeTokenItem.blockchain,
                    signer: transactionSigner.latestSignerType,
                    isToken: feeTokenItem.isToken
                )
            }
        } catch {
            throw mapper.mapError(
                error.toUniversalError(),
                transaction: transactions.last ?? transactions[0]
            )
        }
    }
}

// MARK: - Private

private extension ApproveTransactionDispatcher {
    func buildTransaction(data: ApproveTransactionData, fee: BSDKFee) async throws -> BSDKTransaction {
        let amount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: 0)
        let transaction = try await transactionCreator.createTransaction(
            amount: amount,
            fee: fee,
            destinationAddress: data.toContractAddress,
            contractAddress: data.toContractAddress,
            params: EthereumTransactionParams(data: data.txData)
        )

        return transaction
    }
}
