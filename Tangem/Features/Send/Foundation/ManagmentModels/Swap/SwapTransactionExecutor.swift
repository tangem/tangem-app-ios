//
//  SwapTransactionExecutor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemFoundation

/// Owns the swap transaction dispatch pipeline. Holds dispatch dependencies and
/// consumes a snapshot of swap state to perform a single transaction. No state
/// mutation, no Combine subjects — returns the dispatcher result to the caller.
struct SwapTransactionExecutor {
    let expressManager: ExpressManager
    let expressAPIProvider: ExpressAPIProvider
    let expressPendingTransactionRepository: ExpressPendingTransactionRepository
    let expressUserWalletId: UserWalletId
    let analyticsLogger: SendAnalyticsLogger

    func send(
        source: SendSwapableToken,
        receive: SendReceiveToken,
        loadedPhase: SwapLoadedPhase,
        selectedProvider: ExpressAvailableProvider?
    ) async throws -> TransactionDispatcherResult {
        analyticsLogger.logSwapButtonSwap()

        switch loadedPhase {
        case .permissionRequired:
            assertionFailure("Should called sendApproveTransaction()")
            throw SwapModel.SwapModelError.transactionDataNotFound

        case .previewCEX(let previewCEX):
            guard let selectedProvider else {
                throw SwapModel.SwapModelError.transactionDataNotFound
            }

            let data = try await expressManager.requestData()
            let dispatcher = source.transactionDispatcherProvider.makeCEXTransactionDispatcher()
            let result = try await dispatcher.send(transaction: .cex(data: data, fee: previewCEX.fee))
            analyticsLogger.logSwapTransactionSent(result: result)

            await notifyExpressAboutTransactionDidSent(source: source, data: data, result: result)
            addTransactionToPendingRepository(
                source: source,
                receive: receive,
                provider: selectedProvider.provider,
                fee: previewCEX.fee,
                data: data,
                result: result
            )

            return result

        case .readyToSwap(let readyToSwap):
            guard let selectedProvider else {
                throw SwapModel.SwapModelError.transactionDataNotFound
            }

            let data = readyToSwap.data
            let dispatcher = source.transactionDispatcherProvider.makeDEXTransactionDispatcher()
            let result = try await dispatcher.send(transaction: .dex(data: data, fee: readyToSwap.fee))
            analyticsLogger.logSwapTransactionSent(result: result)

            await notifyExpressAboutTransactionDidSent(source: source, data: data, result: result)
            addTransactionToPendingRepository(
                source: source,
                receive: receive,
                provider: selectedProvider.provider,
                fee: readyToSwap.fee,
                data: data,
                result: result
            )

            return result

        default:
            throw SwapModel.SwapModelError.transactionDataNotFound
        }
    }

    private func notifyExpressAboutTransactionDidSent(
        source: SendSwapableToken,
        data: ExpressTransactionData,
        result: TransactionDispatcherResult
    ) async {
        let expressSentResult = ExpressTransactionSentResult(
            hash: result.hash,
            source: source.tokenItem.expressCurrency,
            address: source.defaultAddressString,
            data: data
        )

        // Ignore error here
        try? await expressAPIProvider.exchangeSent(result: expressSentResult)
    }

    private func addTransactionToPendingRepository(
        source: SendSwapableToken,
        receive: SendReceiveToken,
        provider: ExpressProvider,
        fee: BSDKFee,
        data: ExpressTransactionData,
        result: TransactionDispatcherResult
    ) {
        let sentTransactionData = SentSwapTransactionData(
            expressUserWalletId: expressUserWalletId.stringValue,
            result: result,
            source: source,
            receive: receive,
            fee: fee,
            provider: provider,
            date: Date(),
            expressTransactionData: data
        )

        expressPendingTransactionRepository.swapTransactionDidSend(sentTransactionData)
    }
}
