//
//  TransferTransactionDispatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

class TransferTransactionDispatcher {
    private let walletModel: any WalletModel
    private let transactionSigner: TangemSigner
    private let gaslessTransactionSender: GaslessTransactionSender

    init(
        walletModel: any WalletModel,
        transactionSigner: TangemSigner,
        gaslessTransactionSender: GaslessTransactionSender
    ) {
        self.walletModel = walletModel
        self.transactionSigner = transactionSigner
        self.gaslessTransactionSender = gaslessTransactionSender
    }
}

// MARK: - TransactionDispatcher

extension TransferTransactionDispatcher: TransactionDispatcher {
    var hasNFCInteraction: Bool {
        transactionSigner.hasNFCInteraction
    }

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        guard case .transfer(let transferTransaction) = transaction else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        let mapper = TransactionDispatcherResultMapper()

        do {
            let result = try await send(transaction: transferTransaction)
            walletModel.updateAfterSendingTransaction()

            if walletModel.yieldModuleManager?.state?.state.isEffectivelyActive == true {
                walletModel.yieldModuleManager?.sendTransactionSendEvent(transactionHash: result.hash)
            }

            return result
        } catch {
            AppLogger.error(error: error)
            throw mapper.mapError(error.toUniversalError(), transaction: transaction)
        }
    }

    private func send(transaction: BSDKTransaction) async throws -> TransactionDispatcherResult {
        if walletModel.tokenItem.blockchain.isGaslessTransactionSupported, transaction.fee.amount.type.isToken {
            return try await gaslessTransactionSender.send(transaction: transaction)
        }

        let sendResult = try await walletModel.transactionSender.send(transaction, signer: transactionSigner).async()
        let dispatcherResult = TransactionDispatcherResultMapper().mapResult(
            sendResult,
            blockchain: walletModel.tokenItem.blockchain,
            signer: transactionSigner.latestSignerType,
            isToken: walletModel.tokenItem.isToken
        )
        return dispatcherResult
    }
}
