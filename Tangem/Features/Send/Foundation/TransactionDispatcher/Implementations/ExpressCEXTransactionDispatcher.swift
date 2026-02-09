//
//  ExpressCEXTransactionDispatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation
import TangemExpress

final class ExpressCEXTransactionDispatcher {
    private let walletModel: any WalletModel
    private let transactionSigner: TangemSigner
    private let transferTransactionDispatcher: TransactionDispatcher

    private var tokenItem: TokenItem { walletModel.tokenItem }
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

extension ExpressCEXTransactionDispatcher: TransactionDispatcher {
    var hasNFCInteraction: Bool {
        transactionSigner.hasNFCInteraction
    }

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        guard case .cex(let data, let fee) = transaction else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        let transaction = try await buildTransaction(data: data, fee: fee)
        let result = try await transferTransactionDispatcher.send(transaction: .transfer(transaction))
        return result
    }
}

// MARK: - Private

private extension ExpressCEXTransactionDispatcher {
    func buildTransaction(data: ExpressTransactionData, fee: BSDKFee) async throws -> BSDKTransaction {
        let transactionParams: TransactionParams? = try {
            if let extraDestinationId = data.extraDestinationId, !extraDestinationId.isEmpty {
                // If we received a extraId then try to map it to specific TransactionParams
                let builder = TransactionParamsBuilder(blockchain: tokenItem.blockchain)
                return try builder.transactionParameters(value: extraDestinationId)
            }

            return nil
        }()

        let amount = Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: data.txValue)
        let transaction = try await transactionCreator
            .createTransaction(amount: amount, fee: fee, destinationAddress: data.destinationAddress, params: transactionParams)

        return transaction
    }
}
