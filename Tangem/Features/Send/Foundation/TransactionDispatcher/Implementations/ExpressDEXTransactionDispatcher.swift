//
//  ExpressDEXTransactionDispatcher.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation
import TangemExpress

final class ExpressDEXTransactionDispatcher {
    private let walletModel: any WalletModel
    private let transactionSigner: TangemSigner
    private let transferTransactionDispatcher: TransactionDispatcher

    private var tokenItem: TokenItem { walletModel.tokenItem }
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

extension ExpressDEXTransactionDispatcher: TransactionDispatcher {
    var hasNFCInteraction: Bool {
        transactionSigner.hasNFCInteraction
    }

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        guard case .dex(let data, let fee) = transaction else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        switch walletModel.tokenItem.blockchain {
        case let blockchain where blockchain.isEvm:
            return try await sendEVM(data: data, fee: fee)

        case .solana:
            return try await sendSolana(data: data, fee: fee)

        case let blockchain:
            throw DEXTransactionDispatcherError.dexNotSupported(blockchain: blockchain.displayName)
        }
    }

    func send(transactions: [TransactionDispatcherTransactionType]) async throws -> [TransactionDispatcherResult] {
        guard let lastTransaction = transactions.last else {
            throw TransactionDispatcherResult.Error.transactionNotFound
        }

        guard transactions.count > 1 else {
            return [try await send(transaction: lastTransaction)]
        }

        let blockchain = walletModel.tokenItem.blockchain

        guard blockchain.isEvm else {
            throw DEXTransactionDispatcherError.dexNotSupported(blockchain: blockchain.displayName)
        }

        var builtTransactions: [BSDKTransaction] = []
        for transaction in transactions {
            switch transaction {
            case .approve(let data, let fee):
                builtTransactions.append(try await buildApproveTransaction(data: data, fee: fee))
            case .dex(let data, let fee):
                builtTransactions.append(try await buildTransaction(data: data, fee: fee))
            default:
                throw TransactionDispatcherResult.Error.transactionNotFound
            }
        }

        guard let multipleTransactionsSender = walletModel.multipleTransactionsSender else {
            throw TransactionDispatcherProviderError.transactionNotSupported(
                reason: "MultipleTransactionsSender is not available"
            )
        }

        let mapper = TransactionDispatcherResultMapper()

        do {
            let hashes = try await multipleTransactionsSender.send(builtTransactions, signer: transactionSigner).async()

            return hashes.map { hash in
                mapper.mapResult(
                    hash,
                    blockchain: feeTokenItem.blockchain,
                    signer: transactionSigner.latestSignerType,
                    isToken: feeTokenItem.isToken
                )
            }
        } catch {
            throw mapper.mapError(error.toUniversalError(), transaction: lastTransaction)
        }
    }
}

// MARK: - Private

private extension ExpressDEXTransactionDispatcher {
    func sendEVM(data: ExpressTransactionData, fee: BSDKFee) async throws -> TransactionDispatcherResult {
        let transaction = try await buildTransaction(data: data, fee: fee)
        return try await transferTransactionDispatcher.send(transaction: .transfer(transaction))
    }

    func sendSolana(data: ExpressTransactionData, fee: BSDKFee) async throws -> TransactionDispatcherResult {
        guard let sender = walletModel.compiledTransactionSender else {
            throw TransactionDispatcherResult.Error.actionNotSupported
        }

        let compiled = try buildRawCompiledTransaction(data: data, fee: fee)
        let transactionSendResult = try await sender
            .send(compiledTransaction: compiled, signer: transactionSigner)

        let mapper = TransactionDispatcherResultMapper()
        return mapper.mapResult(
            transactionSendResult,
            blockchain: walletModel.tokenItem.blockchain,
            signer: transactionSigner.latestSignerType,
            isToken: walletModel.tokenItem.isToken
        )
    }

    func buildTransaction(data: ExpressTransactionData, fee: BSDKFee) async throws -> BSDKTransaction {
        guard let txData = data.txData else {
            throw DEXTransactionDispatcherError.transactionDataForSwapOperationNotFound
        }

        let amount = BSDKAmount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: data.txValue)
        let transaction = try await transactionCreator.createTransaction(
            amount: amount,
            fee: fee,
            destinationAddress: data.destinationAddress,
            contractAddress: data.destinationAddress,
            // In EVM-like blockchains we should add the txData to the transaction
            params: EthereumTransactionParams(data: Data(hexString: txData))
        )

        return transaction
    }

    func buildRawCompiledTransaction(data: ExpressTransactionData, fee: Fee) throws -> Data {
        guard let txData = data.txData, let unsignedData = Data(base64Encoded: txData) else {
            throw DEXTransactionDispatcherError.transactionDataForSwapOperationNotFound
        }

        return unsignedData
    }

    func buildApproveTransaction(data: ApproveTransactionData, fee: BSDKFee) async throws -> BSDKTransaction {
        let amount = BSDKAmount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: 0)
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

// MARK: - Error

enum DEXTransactionDispatcherError: LocalizedError {
    case dexNotSupported(blockchain: String)
    case transactionDataForSwapOperationNotFound

    var errorDescription: String? {
        switch self {
        case .dexNotSupported(let blockchain): "DEX is not supported for \(blockchain)"
        case .transactionDataForSwapOperationNotFound: "Transaction data for swap operation not found"
        }
    }
}
