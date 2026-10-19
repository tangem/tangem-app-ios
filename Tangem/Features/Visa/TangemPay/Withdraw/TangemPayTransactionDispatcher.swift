//
//  TangemPayTransactionDispatcher.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemFoundation
import TangemPay
import TangemVisa

struct TangemPayTransactionDispatcher {
    @Injected(\.tangemPayPendingWithdrawExchangesStore)
    private var pendingWithdrawExchangesStore: TangemPayPendingWithdrawExchangesStore

    let userWalletId: UserWalletId
    let withdrawTransactionService: TangemPayWithdrawTransactionService
    let signerFactory: TangemSignerFactory
    let walletPublicKey: Wallet.PublicKey?
    let accountToken: TangemPayAccountToken
}

// MARK: - TransactionDispatcher

extension TangemPayTransactionDispatcher: TransactionDispatcher {
    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        switch transaction {
        case .transfer(let transaction):
            let result = try await sendWithdraw(
                amount: transaction.amount.value,
                destination: transaction.destinationAddress
            )

            return TransactionDispatcherResultMapper().mapResult(result, signer: .none)

        case .cex(let data, _):
            let result = try await sendWithdraw(
                amount: data.txValue,
                destination: data.destinationAddress
            )

            let pendingExchange = TangemPayPendingWithdrawExchange(
                orderId: result.orderID,
                createdAt: Date(),
                tokenItem: accountToken.tokenItem,
                fromAddress: data.sourceAddress ?? accountToken.depositAddress,
                transactionData: data
            )
            pendingWithdrawExchangesStore.add(pendingExchange, userWalletId: userWalletId)

            return TransactionDispatcherResultMapper().mapResult(result, signer: .none)

        default:
            throw TransactionDispatcherResult.Error.transactionNotFound
        }
    }
}

// MARK: - Private

private extension TangemPayTransactionDispatcher {
    func sendWithdraw(amount: Decimal, destination: String) async throws -> TangemPayWithdrawTransactionResult {
        guard let walletPublicKey else {
            throw Error.walletPublicKeyNotFound
        }

        let target = try accountToken.withdrawEligibility.resolveDispatchTarget()

        return try await withdrawTransactionService.sendWithdrawTransaction(
            amount: amount,
            destination: destination,
            walletPublicKey: walletPublicKey,
            target: target
        )
    }
}

// MARK: - Error

extension TangemPayTransactionDispatcher {
    enum Error: LocalizedError {
        case walletPublicKeyNotFound
    }
}
