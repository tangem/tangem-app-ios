//
//  ExpressTransactionDispatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

final class ExpressTransactionDispatcher {
    private let walletModel: any WalletModel
    private let transactionSigner: TangemSigner
    private let sendTransactionDispatcher: TransactionDispatcher

    private let mapper = TransactionDispatcherResultMapper()

    init(
        walletModel: any WalletModel,
        transactionSigner: TangemSigner,
        sendTransactionDispatcher: TransactionDispatcher
    ) {
        self.walletModel = walletModel
        self.transactionSigner = transactionSigner
        self.sendTransactionDispatcher = sendTransactionDispatcher
    }
}

// MARK: - TransactionDispatcher

extension ExpressTransactionDispatcher: TransactionDispatcher {
    var hasNFCInteraction: Bool {
        transactionSigner.hasNFCInteraction
    }

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        guard case .express(let transactionTypeData) = transaction else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        switch transactionTypeData {
        case .compiled(let unsignedData):
            let transactionSendResult = try await send(unsignedData: unsignedData)

            if walletModel.yieldModuleManager?.state?.state.isEffectivelyActive == true {
                walletModel.yieldModuleManager?.sendTransactionSendEvent(transactionHash: transactionSendResult.hash)
            }

            return mapper.mapResult(
                transactionSendResult,
                blockchain: walletModel.tokenItem.blockchain,
                signer: transactionSigner.latestSignerType,
                isToken: walletModel.tokenItem.isToken
            )
        case .default(let transaction):
            return try await sendTransactionDispatcher.send(transaction: .transfer(transaction))
        }
    }
}

// MARK: - Private Implementation

private extension ExpressTransactionDispatcher {
    func send(unsignedData: Data) async throws -> TransactionSendResult {
        guard let sender = walletModel.compiledTransactionSender else {
            throw TransactionDispatcherResult.Error.actionNotSupported
        }

        return try await sender.send(compiledTransaction: unsignedData, signer: transactionSigner)
    }
}
