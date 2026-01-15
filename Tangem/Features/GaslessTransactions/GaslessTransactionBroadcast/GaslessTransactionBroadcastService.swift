//
//  GaslessTransactionBroadcastService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

class GaslessTransactionBroadcastService {
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

    func send(transaction: BSDKTransaction) async throws -> TransactionSendResult {
        guard let ethereumGaslessTransactionBroadcaster = walletModel.ethereumGaslessTransactionBroadcaster else {
            throw TransactionDispatcherResult.Error.actionNotSupported
        }

        guard transaction.fee.amount.type.isToken else {
            assertionFailure("Gasless fee should be in token")
            throw TransactionDispatcherResult.Error.actionNotSupported
        }

        let buildTransaction = try await gaslessTransactionBuilder.buildGaslessTransaction(
            bsdkTransaction: transaction
        )

        let signedResult = try await gaslessTransactionsNetworkManager.signGaslessTransaction(buildTransaction)
        let hash = try await ethereumGaslessTransactionBroadcaster.broadcast(
            transaction: transaction,
            compiledTransactionHex: signedResult.signedTransaction
        )

        return hash
    }
}
