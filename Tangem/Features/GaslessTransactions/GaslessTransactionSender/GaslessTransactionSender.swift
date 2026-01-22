//
//  GaslessTransactionSender.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

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

        let buildTransaction = try await gaslessTransactionBuilder.buildGaslessTransaction(
            bsdkTransaction: transaction
        )

        let transactionHash = try await gaslessTransactionsNetworkManager.sendGaslessTransaction(buildTransaction)
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
