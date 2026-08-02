//
//  TronGaslessTransactionSender.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

final class TronGaslessTransactionSender {
    @Injected(\.gaslessTransactionsNetworkManager)
    private var networkManager: GaslessTransactionsNetworkManager

    private let walletModel: any WalletModel
    private let transactionSigner: TangemSigner

    init(walletModel: any WalletModel, transactionSigner: TangemSigner) {
        self.walletModel = walletModel
        self.transactionSigner = transactionSigner
    }

    func send(transaction: BSDKTransaction) async throws -> TransactionDispatcherResult {
        guard FeatureProvider.isAvailable(.tronGasless),
              transaction.amount.type.isToken,
              transaction.fee.amount.type.isToken,
              let feeToken = transaction.fee.amount.type.token,
              let builder = walletModel.tronGaslessTransactionsBuilder else {
            throw TransactionDispatcherResult.Error.actionNotSupported
        }

        let quote = try resolveQuote(transaction: transaction, feeToken: feeToken)
        try validateBalance(transaction: transaction, quote: quote, feeToken: feeToken)

        let compensationTransaction = try makeCompensationTransaction(
            originalTransaction: transaction,
            quote: quote,
            feeToken: feeToken
        )
        let originalTransaction = makeOriginalTransaction(transaction, quote: quote)
        let signedTransactions = try await builder.buildForGaslessSubmit(
            originalTransaction: originalTransaction,
            compensationTransaction: compensationTransaction,
            signer: transactionSigner
        )

        let response = try await networkManager.submitTronGaslessTransaction(
            .init(
                quoteId: quote.quoteId,
                signedCompensationTx: signedTransactions.signedCompensationTx,
                signedOriginalTx: signedTransactions.signedOriginalTx
            )
        )

        switch response.status {
        case .broadcast:
            break
        case .failed, .partialFailed:
            throw ValidationError.transactionFailed
        }

        walletModel.pendingTransactionRecordAdder?.addPendingTransaction(originalTransaction, hash: response.originalTxHash)
        walletModel.pendingTransactionRecordAdder?.addPendingTransaction(compensationTransaction, hash: response.compensationTxHash)

        let sendResult = GaslessTransactionSendResult(
            hash: response.originalTxHash,
            currentProviderHost: networkManager.currentHost
        )

        return TransactionDispatcherResultMapper().mapResult(
            sendResult,
            blockchain: walletModel.tokenItem.blockchain,
            signer: transactionSigner.latestSignerType,
            isToken: walletModel.tokenItem.isToken
        )
    }
}

// MARK: - Private

private extension TronGaslessTransactionSender {
    func resolveQuote(transaction: BSDKTransaction, feeToken: BSDKToken) throws -> TronGaslessFeeParameters {
        guard let parameters = transaction.fee.parameters as? TronGaslessFeeParameters,
              parameters.expiresAt > Date().addingTimeInterval(TronGaslessFeeParameters.expirationBuffer) else {
            throw TransactionDispatcherResult.Error.informationRelevanceServiceError
        }

        guard parameters.compensationToken == feeToken.contractAddress else {
            throw ValidationError.compensationTokenMismatch
        }

        return parameters
    }

    func makeOriginalTransaction(_ transaction: BSDKTransaction, quote: TronGaslessFeeParameters) -> BSDKTransaction {
        BSDKTransaction(
            amount: transaction.amount,
            fee: makeFee(quote: quote, feeToken: transaction.fee.amount.type.token),
            sourceAddress: transaction.sourceAddress,
            destinationAddress: transaction.destinationAddress,
            changeAddress: transaction.changeAddress,
            contractAddress: transaction.contractAddress,
            params: transaction.params
        )
    }

    func makeCompensationTransaction(
        originalTransaction: BSDKTransaction,
        quote: TronGaslessFeeParameters,
        feeToken: BSDKToken
    ) throws -> BSDKTransaction {
        let compensationAmount = try makeAmount(rawValue: quote.compensationAmountRaw, token: feeToken)

        return BSDKTransaction(
            amount: compensationAmount,
            fee: Fee(.zeroCoin(for: walletModel.tokenItem.blockchain)),
            sourceAddress: originalTransaction.sourceAddress,
            destinationAddress: quote.feeRecipient,
            changeAddress: originalTransaction.changeAddress
        )
    }

    func makeFee(quote: TronGaslessFeeParameters, feeToken: BSDKToken?) -> BSDKFee {
        guard let feeToken,
              let compensationAmount = try? makeAmount(rawValue: quote.compensationAmountRaw, token: feeToken) else {
            return Fee(.zeroCoin(for: walletModel.tokenItem.blockchain), parameters: quote)
        }

        return Fee(compensationAmount, parameters: quote)
    }

    func validateBalance(transaction: BSDKTransaction, quote: TronGaslessFeeParameters, feeToken: BSDKToken) throws {
        guard transaction.amount.type.token?.contractAddress == feeToken.contractAddress else {
            return
        }

        let compensation = try makeAmount(rawValue: quote.compensationAmountRaw, token: feeToken)
        guard transaction.amount.value + compensation.value <= walletModel.availableBalanceProvider.balanceType.value ?? 0 else {
            throw TokenFeeProviderError.notEnoughGaslessFeeBalance
        }
    }

    func makeAmount(rawValue: String, token: BSDKToken) throws -> BSDKAmount {
        guard let rawDecimal = Decimal(stringValue: rawValue) else {
            throw TransactionDispatcherResult.Error.actionNotSupported
        }

        return BSDKAmount(with: token, value: rawDecimal / pow(10, token.decimalCount))
    }

    enum ValidationError: LocalizedError {
        case compensationTokenMismatch
        case transactionFailed

        var errorDescription: String? {
            switch self {
            case .compensationTokenMismatch:
                "Fee token contract address does not match the compensation token"
            case .transactionFailed:
                "Tron gasless transaction failed"
            }
        }
    }
}
