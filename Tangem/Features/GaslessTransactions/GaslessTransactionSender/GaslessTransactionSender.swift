//
//  GaslessTransactionSender.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

final class GaslessTransactionSender {
    @Injected(\.gaslessTransactionsNetworkManager)
    private var gaslessTransactionsNetworkManager: GaslessTransactionsNetworkManager

    private let walletModel: any WalletModel
    private let transactionSigner: TangemSigner
    private let gaslessTransactionBuilder: GaslessTransactionBuilder

    init(
        walletModel: any WalletModel,
        transactionSigner: TangemSigner,
        gaslessTransactionBuilder: GaslessTransactionBuilder
    ) {
        self.walletModel = walletModel
        self.transactionSigner = transactionSigner
        self.gaslessTransactionBuilder = gaslessTransactionBuilder
    }

    func send(transaction: BSDKTransaction) async throws -> TransactionDispatcherResult {
        guard transaction.fee.amount.type.isToken else {
            assertionFailure("Gasless fee should be in token")
            throw TransactionDispatcherResult.Error.actionNotSupported
        }

        guard let feeRecipientAddress = await gaslessTransactionsNetworkManager.feeRecipientAddress else {
            throw GaslessTransactionSenderError.noFeeRecipientAddress
        }

        let buildTransaction = try await gaslessTransactionBuilder.buildGaslessTransactionRequest(
            bsdkTransaction: transaction, feeRecipientAddress: feeRecipientAddress
        )

        let transactionHash: String
        switch buildTransaction {
        case .single(let transaction):
            transactionHash = try await gaslessTransactionsNetworkManager.sendGaslessTransaction(transaction)
        case .batch(let transaction):
            transactionHash = try await gaslessTransactionsNetworkManager.sendGaslessBatchTransaction(transaction)
        }

        walletModel.pendingTransactionRecordAdder?.addPendingTransaction(transaction, hash: transactionHash)

        let sendResult = GaslessTransactionSendResult(hash: transactionHash, currentProviderHost: gaslessTransactionsNetworkManager.currentHost)

        let dispatcherResult = TransactionDispatcherResultMapper().mapResult(
            sendResult,
            blockchain: walletModel.tokenItem.blockchain,
            signer: transactionSigner.latestSignerType,
            isToken: walletModel.tokenItem.isToken
        )

        return dispatcherResult
    }
}

// MARK: - GaslessMultipleTransactionSending

protocol GaslessMultipleTransactionSending {
    func send(transactions: [BSDKTransaction]) async throws -> [TransactionDispatcherResult]
}

// MARK: - Approve & swap flow

extension GaslessTransactionSender: GaslessMultipleTransactionSending {
    func send(transactions: [BSDKTransaction]) async throws -> [TransactionDispatcherResult] {
        guard transactions.allSatisfy({ $0.fee.amount.type.isToken }) else {
            assertionFailure("Gasless fee should be in token")
            throw TransactionDispatcherResult.Error.actionNotSupported
        }

        guard let feeRecipientAddress = await gaslessTransactionsNetworkManager.feeRecipientAddress else {
            throw GaslessTransactionSenderError.noFeeRecipientAddress
        }

        let gaslessTransactions = try await gaslessTransactionBuilder.buildGaslessTransactions(
            bsdkTransactions: transactions, feeRecipientAddress: feeRecipientAddress
        )

        let mapper = TransactionDispatcherResultMapper()
        var results: [TransactionDispatcherResult] = []

        for (index, gaslessTransaction) in gaslessTransactions.enumerated() {
            if index > 0, let requiredNonce = Int(gaslessTransaction.gaslessTransaction.nonce) {
                try await waitForSmartContractNonce(requiredNonce)
            }

            let transactionHash = try await gaslessTransactionsNetworkManager.sendGaslessTransaction(gaslessTransaction)

            walletModel.pendingTransactionRecordAdder?.addPendingTransaction(transactions[index], hash: transactionHash)

            let sendResult = GaslessTransactionSendResult(hash: transactionHash, currentProviderHost: gaslessTransactionsNetworkManager.currentHost)

            results.append(mapper.mapResult(
                sendResult,
                blockchain: walletModel.tokenItem.blockchain,
                signer: transactionSigner.latestSignerType,
                isToken: walletModel.tokenItem.isToken
            ))
        }

        return results
    }

    private func waitForSmartContractNonce(_ nonce: Int) async throws {
        guard let networkProvider = walletModel.ethereumNetworkProvider else {
            throw GaslessTransactionSenderError.previousTransactionNotMined
        }

        let polling = PollingSequence(
            interval: Constants.nonceWaitInterval,
            request: { [walletModel] in
                try await networkProvider.getSmartContractNonce(for: walletModel.defaultAddressString).async()
            }
        )

        let minedNonce = await polling
            .prefix(Constants.nonceWaitAttempts)
            .first { result in
                guard let currentNonce = result.value else { return false }
                return currentNonce >= nonce
            }

        try Task.checkCancellation()

        guard minedNonce != nil else {
            throw GaslessTransactionSenderError.previousTransactionNotMined
        }
    }

    private enum Constants {
        static let nonceWaitAttempts = 30
        static let nonceWaitInterval: TimeInterval = 2
    }
}

extension GaslessTransactionSender {
    enum GaslessTransactionSenderError: Error {
        case noFeeRecipientAddress
        case previousTransactionNotMined
    }
}
