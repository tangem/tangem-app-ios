//
//  SendTransactionDispatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

class SendTransactionDispatcher {
    private let walletModel: any WalletModel
    private let transactionSigner: TangemSigner
    private let gaslessTransactionBroadcastService: GaslessTransactionBroadcastService

    init(
        walletModel: any WalletModel,
        transactionSigner: TangemSigner,
        gaslessTransactionBroadcastService: GaslessTransactionBroadcastService
    ) {
        self.walletModel = walletModel
        self.transactionSigner = transactionSigner
        self.gaslessTransactionBroadcastService = gaslessTransactionBroadcastService
    }
}

// MARK: - TransactionDispatcher

extension SendTransactionDispatcher: TransactionDispatcher {
    var hasNFCInteraction: Bool {
        transactionSigner.hasNFCInteraction
    }

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        guard case .transfer(let transferTransaction) = transaction else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        let mapper = TransactionDispatcherResultMapper()

        do {
            let hash = try await send(transaction: transferTransaction)
            walletModel.updateAfterSendingTransaction()

            if walletModel.yieldModuleManager?.state?.state.isEffectivelyActive == true {
                walletModel.yieldModuleManager?.sendTransactionSendEvent(transactionHash: hash.hash)
            }

            return mapper.mapResult(
                hash,
                blockchain: walletModel.tokenItem.blockchain,
                signer: transactionSigner.latestSignerType,
                isToken: walletModel.tokenItem.isToken
            )
        } catch {
            AppLogger.error(error: error)
            throw mapper.mapError(error.toUniversalError(), transaction: transaction)
        }
    }

    private func send(transaction: BSDKTransaction) async throws -> TransactionSendResult {
        if walletModel.tokenItem.blockchain.isGaslessTransactionSupported, transaction.fee.amount.type.isToken {
            return try await gaslessTransactionBroadcastService.send(transaction: transaction)
        }

        return try await walletModel.transactionSender.send(transaction, signer: transactionSigner).async()
    }
}
