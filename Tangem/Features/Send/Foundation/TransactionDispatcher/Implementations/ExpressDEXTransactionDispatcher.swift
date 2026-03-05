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
            let transaction = try await buildTransaction(data: data, fee: fee)
            let result = try await transferTransactionDispatcher.send(transaction: .transfer(transaction))
            return result

        case .solana:
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

        case let blockchain:
            throw DEXTransactionDispatcherError.dexNotSupported(blockchain: blockchain.displayName)
        }
    }
}

// MARK: - Private

private extension ExpressDEXTransactionDispatcher {
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
