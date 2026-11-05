//
//  SolanaGaslessTransactionSender.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

final class SolanaGaslessTransactionSender {
    @Injected(\.gaslessTransactionsNetworkManager)
    private var networkManager: GaslessTransactionsNetworkManager

    private let walletModel: any WalletModel
    private let transactionSigner: TangemSigner

    init(walletModel: any WalletModel, transactionSigner: TangemSigner) {
        self.walletModel = walletModel
        self.transactionSigner = transactionSigner
    }

    func send(transaction: BSDKTransaction) async throws -> TransactionDispatcherResult {
        let (builder, parameters) = try resolve(fee: transaction.fee)

        let networkTransaction = BSDKTransaction(
            amount: transaction.amount,
            fee: parameters.networkFee,
            sourceAddress: transaction.sourceAddress,
            destinationAddress: transaction.destinationAddress,
            changeAddress: transaction.changeAddress,
            contractAddress: transaction.contractAddress,
            params: transaction.params
        )

        let gaslessTransaction = try await builder.buildGaslessTransaction(
            networkTransaction,
            feePayer: parameters.feePayer,
            signer: transactionSigner
        )

        let signature = try await submit(gaslessTransaction)
        walletModel.pendingTransactionRecordAdder?.addPendingTransaction(transaction, hash: signature)

        return mapResult(signature: signature)
    }

    func send(compiledTransaction: Data, fee: BSDKFee) async throws -> TransactionDispatcherResult {
        let (builder, parameters) = try resolve(fee: fee)

        let gaslessTransaction = try await builder.buildGaslessTransaction(
            compiledTransaction: compiledTransaction,
            feePayer: parameters.feePayer,
            signer: transactionSigner
        )

        let signature = try await submit(gaslessTransaction)
        return mapResult(signature: signature)
    }
}

// MARK: - Private

private extension SolanaGaslessTransactionSender {
    func resolve(fee: BSDKFee) throws -> (any SolanaGaslessTransactionBuilder, SolanaGaslessFeeParameters) {
        guard let parameters = fee.parameters as? SolanaGaslessFeeParameters,
              let builder = walletModel.solanaGaslessTransactionBuilder else {
            throw TransactionDispatcherResult.Error.actionNotSupported
        }

        return (builder, parameters)
    }

    func submit(_ transaction: SolanaGaslessTransaction) async throws -> String {
        let request = GaslessTransactionsDTO.Request.SolanaSubmit(
            transaction: transaction.serialized.base64EncodedString(),
            lastValidBlockHeight: transaction.lastValidBlockHeight
        )

        return try await networkManager.submitSolanaGaslessTransaction(request, userWalletId: walletModel.userWalletId)
    }

    func mapResult(signature: String) -> TransactionDispatcherResult {
        let sendResult = GaslessTransactionSendResult(hash: signature, currentProviderHost: networkManager.currentHost)

        return TransactionDispatcherResultMapper().mapResult(
            sendResult,
            blockchain: walletModel.tokenItem.blockchain,
            signer: transactionSigner.latestSignerType,
            isToken: walletModel.tokenItem.isToken
        )
    }
}
