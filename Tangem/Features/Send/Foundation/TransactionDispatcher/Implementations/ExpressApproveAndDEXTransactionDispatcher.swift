//
//  ExpressApproveAndDEXTransactionDispatcher.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation
import TangemExpress

final class ExpressApproveAndDEXTransactionDispatcher {
    private let walletModel: any WalletModel
    private let transactionSigner: TangemSigner
    private let gaslessTransactionSender: GaslessTransactionSender

    private var feeTokenItem: TokenItem { walletModel.feeTokenItem }
    private var transactionCreator: TransactionCreator { walletModel.transactionCreator }

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

extension ExpressApproveAndDEXTransactionDispatcher: TransactionDispatcher {
    var hasNFCInteraction: Bool {
        transactionSigner.hasNFCInteraction
    }

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        guard case .approveAndDex(let data, let fee, let approveData) = transaction else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        let blockchain = walletModel.tokenItem.blockchain
        guard blockchain.isEvm else {
            throw DEXTransactionDispatcherError.dexNotSupported(blockchain: blockchain.displayName)
        }

        guard let combinedFeeParameters = fee.parameters as? ApproveWithSwapFeeParameters else {
            throw TransactionDispatcherResult.Error.feeNotFound
        }

        let swapTransactionFee = combinedFeeParameters.swapFee(total: fee)
        let approveTransaction = try await buildApproveTransaction(data: approveData, fee: combinedFeeParameters.approveFee)
        let swapTransaction = try await buildSwapTransaction(data: data, fee: swapTransactionFee)

        if blockchain.isGaslessTransactionSupported, swapTransactionFee.amount.type.isToken {
            let gaslessResults: [TransactionDispatcherResult]
            do {
                gaslessResults = try await gaslessTransactionSender.send(transactions: [approveTransaction, swapTransaction])
            } catch {
                throw TransactionDispatcherResultMapper().mapError(error.toUniversalError(), transaction: transaction)
            }

            walletModel.updateAfterSendingTransaction()

            guard let swapResult = gaslessResults.last else {
                throw TransactionDispatcherResult.Error.transactionNotFound
            }

            return swapResult
        }

        let builtTransactions = [approveTransaction, swapTransaction]

        guard let multipleTransactionsSender = walletModel.multipleTransactionsSender else {
            throw TransactionDispatcherProviderError.transactionNotSupported(
                reason: "MultipleTransactionsSender is not available"
            )
        }

        let mapper = TransactionDispatcherResultMapper()
        let results: [TransactionDispatcherResult]

        do {
            let hashes = try await multipleTransactionsSender.send(builtTransactions, signer: transactionSigner).async()
            results = hashes.map { hash in
                mapper.mapResult(
                    hash,
                    blockchain: feeTokenItem.blockchain,
                    signer: transactionSigner.latestSignerType,
                    isToken: feeTokenItem.isToken
                )
            }
        } catch {
            throw mapper.mapError(error.toUniversalError(), transaction: transaction)
        }

        walletModel.updateAfterSendingTransaction()

        guard let result = results.last else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        return result
    }
}

// MARK: - Private

private extension ExpressApproveAndDEXTransactionDispatcher {
    func buildSwapTransaction(data: ExpressTransactionData, fee: BSDKFee) async throws -> BSDKTransaction {
        guard let txData = data.txData else {
            throw DEXTransactionDispatcherError.transactionDataForSwapOperationNotFound
        }

        let amount = BSDKAmount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: data.txValue)
        return try await transactionCreator.createTransaction(
            amount: amount,
            fee: fee,
            destinationAddress: data.destinationAddress,
            contractAddress: data.destinationAddress,
            params: EthereumTransactionParams(data: Data(hexString: txData))
        )
    }

    func buildApproveTransaction(data: ApproveTransactionData, fee: BSDKFee) async throws -> BSDKTransaction {
        let amount = BSDKAmount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: 0)
        return try await transactionCreator.createTransaction(
            amount: amount,
            fee: fee,
            destinationAddress: data.toContractAddress,
            contractAddress: data.toContractAddress,
            params: EthereumTransactionParams(data: data.txData)
        )
    }
}
