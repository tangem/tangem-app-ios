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

    private let mapper = TransactionDispatcherResultMapper()

    init(
        walletModel: any WalletModel,
        transactionSigner: TangemSigner
    ) {
        self.walletModel = walletModel
        self.transactionSigner = transactionSigner
    }
}

// MARK: - TransactionDispatcher

extension SendTransactionDispatcher: TransactionDispatcher {
    func send(transaction: SendTransactionType) async throws -> TransactionDispatcherResult {
        let transactionSendResult: TransactionSendResult

        switch transaction {
        case .transfer(let transferTransaction):
            do {
                transactionSendResult = try await sendTransfer(transaction: transferTransaction)
            } catch {
                AppLogger.error(error: error)
                throw mapper.mapError(error.toUniversalError(), transaction: transaction)
            }
        case .staking:
            throw TransactionDispatcherResult.Error.transactionNotFound
        case .express(let compiledTransaction):
            do {
                transactionSendResult = try await sendExpress(transaction: compiledTransaction)
            } catch {
                AppLogger.error(error: error)
                throw mapper.mapError(error.toUniversalError(), transaction: transaction)
            }
        }

        return mapper.mapResult(
            transactionSendResult,
            blockchain: walletModel.tokenItem.blockchain,
            signer: transactionSigner.latestSignerType
        )
    }
}

// MARK: - Private Implementation

private extension SendTransactionDispatcher {
    func sendTransfer(transaction: BlockchainSdk.Transaction) async throws -> TransactionSendResult {
        let sendResult = try await walletModel.transactionSender.send(transaction, signer: transactionSigner).async()
        walletModel.updateAfterSendingTransaction()
        return sendResult
    }

    func sendExpress(transaction: ExpressTransactionResult) async throws -> TransactionSendResult {
        switch transaction {
        case .default(let transfer):
            return try await sendTransfer(transaction: transfer)
        case .unsigned(let unsignedData):
            guard let sender = walletModel.compiledTransactionSender else {
                throw TransactionDispatcherResult.Error.actionNotSupported
            }

            return try await sender.send(unsigned: unsignedData, signer: transactionSigner)
        }
    }
}
