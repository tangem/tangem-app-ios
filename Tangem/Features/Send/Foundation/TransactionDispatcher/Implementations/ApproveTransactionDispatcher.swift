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
        guard case .approve(let data) = transaction else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        let transaction = try await buildTransaction(data: data)
        let result = try await transferTransactionDispatcher.send(transaction: .transfer(transaction))
        return result
    }
}

// MARK: - Private

private extension ApproveTransactionDispatcher {
    func buildTransaction(data: ApproveTransactionData) async throws -> BSDKTransaction {
        let amount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: 0)
        let transaction = try await transactionCreator.createTransaction(
            amount: amount,
            fee: data.fee,
            destinationAddress: data.toContractAddress,
            contractAddress: data.toContractAddress,
            params: EthereumTransactionParams(data: data.txData)
        )

        return transaction
    }
}
